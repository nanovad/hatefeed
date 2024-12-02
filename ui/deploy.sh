#!/usr/bin/env bash
set -e # Exit as soon as an error occurs

echo ">>> Running 'flutter build web --release'"
flutter build web --release
echo ">>> Done"

# Parse the version number out of the json version manifest
build_num=$(grep -Po '"version":.*?[^\\]"(?=,)' build/web/version.json | awk -F":" '{print $2}' | tr -d \")
echo "Build number: $build_num"
out_archive_name="hatefeed_ui_$build_num.xz"
echo "Output archive name: $out_archive_name"
out_archive_path="build/$out_archive_name"
echo "Output archive path: $out_archive_path"

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
    ssh "hatefeed.nanovad.com" -t "HATEFEED_VERSION=\"$build_num\" bash deploy.sh"
fi
echo "All done!"
