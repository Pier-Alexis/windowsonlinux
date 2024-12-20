#!/bin/bash
echo "=== Configuration of MIME association for WindowsOnLinux ==="
echo "application/x-ms-dos-executable exe" | sudo tee /usr/share/mime/packages/application-x-ms-dos-executable.xml
echo "application/x-msi msi" | sudo tee /usr/share/mime/packages/application-x-msi.xml
# Update MIME base
sudo update-mime-database /usr/share/mime
sudo update-desktop-database
echo "MIME associations finished ! WindowsOnLinux is now recommanded for opening .exe and .msi files."
