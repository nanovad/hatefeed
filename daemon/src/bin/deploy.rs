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
    std::fs::remove_file(IMAGE_FILE).expect(format!("Failed to remove {IMAGE_FILE}").as_str());

    ExitCode::SUCCESS
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
        .expect(format!("Failed to run {}", cmd_formatted).as_str());
    {
        let stdout = cmd
            .stdout
            .as_mut()
            .expect("Failed to get stdout handle for command");
        let stdout_reader = BufReader::new(stdout);
        let stdout_lines = stdout_reader.lines();
        for line in stdout_lines {
            if let Ok(line_ok) = line {
                println!("{}", line_ok);
            }
        }
    }

    let status = cmd
        .wait()
        .expect(format!("Failed: {}", cmd_formatted).as_str());
    if !status.success() {
        panic!("Failed to run {}", cmd_formatted);
    }
}
