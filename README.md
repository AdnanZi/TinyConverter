# Tiny Converter

Tiny converter is a small currency converter iOS app. It works with https://fixer.io service, enabling simple conversion of currency rates. Note that it uses the free plan of fixer.io, which means it has following limitations comparing to premium plans:

* It supports only 1000 requests a month, but this is not an issue since app is fetching data once a day (or every 2 hours at most);
* It doesn't support SSL, which means there could be some issues when installing the app on Apple device;
* It supports only one base currency, which is Euro. This is mitigated in the app by cross-exchanging all currencies by comparing them to Euro;

The app works on all iOS devices with OS versions 9 and above, which means iPhone 4s and newer are supported. 

User can select amongst all currencies support by the service. It also works cross-selecting target as base. 
Data is cached on device, so it will theoretically work with no limits without internet connection, as long as data is fetched from the service at least once. Background fetch is also in place to refresh data - it's set up to trigger every two hours but it will check the date of cached version and update only if the data is older than one calendar day. The interval is configurable in Settings.

The app is designed using MVVM-C app architecture, using XCode 10/11 and Swift 5. No 3rd party libraries are used for bindings - Key-Value Observing is used to create bindings between view (controller) and view model. 
All dependecies are injected so that they can easily be replaced with mocked versions to make unit testing possible. Model is currently fully unit tested, with view model and API service coming later. 

CocoaPods are used for dependencies as Carthage (preferred) hasn't been updated for XCode 11. All pods are pushed to the repo so the project builds as it is.
