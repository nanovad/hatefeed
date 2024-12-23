#!/usr/bin/env bash
set -e # Exit as soon as an error occurs

echo ">>> Running 'flutter build web --release'"
flutter build web --release
echo ">>> Done"

# Parse the version number out of the json version manifest
ver_num=$(grep -Po '"version":.*?[^\\]"(?=,)' build/web/version.json | awk -F":" '{print $2}' | tr -d \")
build_num=$(grep -Po '"build_number".*?[^\\]"(?=,)' build/web/version.json | awk -F ":" '{print $2'} | tr -d \")
echo "Version number: $ver_num"
echo "Build number: $build_num"
ver_and_build="${ver_num}_$build_num"
out_archive_name="hatefeed_ui_$ver_and_build.xz"
echo "Output archive name: $out_archive_name"
out_archive_path="build/$out_archive_name"
echo "Output archive path: $out_archive_path"

if [ -f "$out_archive_path" ]; then
    echo -ne "\n\e[31mWarning: The archive file for version $ver_and_build already exists. "
    echo -e "(Did you forget to bump the version number?)\e[0m"
    read -p "Continue, overwriting this file? (Y/N): " ignore_ver_exists
    if [[ $ignore_ver_exists != [yY] ]]; then
        echo "Quitting"
        exit 1
    fi
fi

# -Force will overwrite
# powershell -Command "Compress-Archive -Path 'build/web' -DestinationPath '$out_archive_path' -Force"
# zip -d "build/web" -o "$out_zip_abs"
echo ">>> Creating archive..."
tar -cJf "$out_archive_path" -C "build/web" .
echo "Done"

echo ">>> Running 'scp \"$out_archive_path\" \"hatefeed.nanovad.com:ui_deploy/\"'"
scp "$out_archive_path" "hatefeed.nanovad.com:ui_deploy/"

read -p "Deploy into production? (Y/N): " deploy_prod
if [[ $deploy_prod == [yY] ]]; then
    ssh "hatefeed.nanovad.com" -t "HATEFEED_VERSION=\"$ver_and_build\" bash deploy.sh"
fi
echo "All done!"
