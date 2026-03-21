use std::{
    env::args,
    ffi::OsStr,
    io::{BufRead, BufReader},
    process::{Command, ExitCode, Stdio},
};

const IMAGE_FILE: &str = "hatefeed.tar";

fn main() -> ExitCode {
    let mut args = args();
    if args.len() < 2 {
        eprintln!("Usage: ./deploy <remote_hostname>");
        return ExitCode::FAILURE;
    }
    args.next();
    let host_name = match args.next() {
        Some(v) => v,
        None => panic!("Unable to parse second arg"),
    };
    run_streamed("docker", ["build", "-t", "hatefeed_daemon", "."]);
    run_streamed("docker", ["save", "hatefeed_daemon", "-o", IMAGE_FILE]);
    run_streamed("scp", [IMAGE_FILE, format!("{host_name}:").as_str()]);
    let docker_load_cmd: String = format!("docker load -i {IMAGE_FILE}");
    run_streamed("ssh", ["hatefeed.ing", docker_load_cmd.as_str()]);
    std::fs::remove_file(IMAGE_FILE)
        .unwrap_or_else(|e| panic!("Failed to remove {IMAGE_FILE}: {e}"));

    return ExitCode::SUCCESS;
}

fn run_streamed<I, S>(binary: &str, args: I)
where
    I: IntoIterator<Item = S>,
    I: std::fmt::Debug,
    S: AsRef<OsStr>,
{
    let cmd_formatted = format!("{} {:?}", binary, args);
    let mut cmd = Command::new(binary)
        .args(args)
        .stdout(Stdio::piped())
        .spawn()
        .unwrap_or_else(|e| panic!("Failed to run {cmd_formatted}: {e}"));
    {
        let stdout = cmd
            .stdout
            .as_mut()
            .expect("Failed to get stdout handle for command");
        let stdout_reader = BufReader::new(stdout);
        for line in stdout_reader.lines().map_while(Result::ok) {
            println!("{}", line);
        }
    }

    let status = cmd
        .wait()
        .unwrap_or_else(|e| panic!("Failed: {cmd_formatted}: {e}"));
    if !status.success() {
        panic!("Failed to run {}", cmd_formatted);
    }
}
