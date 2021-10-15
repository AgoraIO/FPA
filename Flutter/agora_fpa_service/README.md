# agora_fpa_service

## Getting Started
### Requirement
* [flutter](https://flutter.dev/docs/get-started/install)

### Setup
* Clone [FPA](https://bitbucket.agoralab.co/projects/ADUC/repos/fpa_service/browse?at=refs%2Fheads%2Fdev%2Ffpa_proxy) and agora_fpa_service in the same directory
```
|__agora_fpa_service
|__fpa_service
```
* Setup the the FPA project, pls follow [README.md](https://bitbucket.agoralab.co/projects/ADUC/repos/fpa_service/browse?at=refs%2Fheads%2Fdev%2Ffpa_proxy)

### Run Android

* You can run the android example by using `flutter run` directly, 
```
cd FPA/Flutter/agora_fpa_service/example
flutter run
```
* Or open the `example/android` on Android Studio and run it

### Run iOS
* First build the iOS framework, run
```
cd FPA/Flutter/agora_fpa_service
bash build-ios.sh
```
* Open the `example/ios` on Xcode, and run it
