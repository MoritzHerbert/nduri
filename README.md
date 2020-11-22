# Nondisruptive user re-identification

[![CI Status](http://img.shields.io/travis/__GITHUB_USERNAME__/nduri.svg?style=flat)](https://travis-ci.org/__GITHUB_USERNAME__/nduri)
![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/__GITHUB_USERNAME__/nduri)
[![License](https://img.shields.io/github/license/__GITHUB_USERNAME__/nduri)](LICENSE)

> :warning: **Prototype not ready for use yet**

To enable users to use mobile B2B apps freely after the initial login, without endangering e.g. the confidentiality of the mass of customer data inside, a concept of re-identifying the user in a non-disruptive way was evaluated within my [master thesis](master_thesis.pdf).

This prototype contains a selection of measurements taken by various sensors of an iPad. Therefore, this swift module was embedded in a B2B application and the logged measurements were exported for manual analysis.

### Purpose
The measurements are supposed to serve as basis for a user’s biometric profile, which is matched against the measurements taken after a certain point in time. The usefulness of the particular measurements and metrics was evaluated as part of my [thesis](master_thesis.pdf).

### TODOs / Vision
To complete this approach, I suggest to use Swift's [Core ML Framework](https://developer.apple.com/documentation/coreml).
It offers the option to create a custom machine learning model, that can be trained to hold the analysed measurements, or if needed even more data, to make decisions regarding the authenticity of the user.

Ultimately, the library should notify its host application in case of anomalies in the user's behaviour, leading to immediate session termination.

## Example

To run the example project, clone this repo, and open iOS nduri.xcworkspace from the iOS Example directory.
It will print the recorded measurement to the console and visualize swipe gestures in the iPad's screen.


<!--## Requirements-->



## Installation

Add this to your project using Swift Package Manager. In Xcode that is simply: File > Swift Packages > Add Package Dependency... and you're done. Alternative installations options are shown below for legacy projects.

## Author

__GITHUB_USERNAME__

## License

nduri is available under the MIT license. See [the LICENSE file](LICENSE) for more information.
