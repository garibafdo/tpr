cd TipitakaPaliReader.AppDir

cp -r ~/git/tipitaka-pali-reader/build/linux/x64/release/bundle/* .

# Navigate back to the project root
cd ..


# Download the AppImage tool
#wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
#wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
#chmod +x appimagetool-x86_64.AppImage

#change the permissions of the app run file
chmod +x TipitakaPaliReader.AppDir/AppRun
chmod +x TipitakaPaliReader.AppDir/tipitaka_pali_reader

# Build the AppImage
#ARCH=x86_64 ./appimagetool-x86_64.AppImage TipitakaPaliReader.AppDir/ tipitaka_pali_reader.AppImage
./appimagetool-x86_64.AppImage TipitakaPaliReader.AppDir/ tipitaka_pali_reader.AppImage

cp tipitaka_pali_reader.AppImage ~/Desktop/TPR/
