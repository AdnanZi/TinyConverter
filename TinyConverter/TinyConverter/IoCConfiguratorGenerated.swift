

import NeedleFoundation
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class ConverterDependency74994152a44d90efb0bdProvider: ConverterDependency {
    var configuration: Configuration {
        return rootComponent.configuration
    }
    var store: Store {
        return rootComponent.store
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->ConverterComponent
private func factorybea2fe96e50ead89d19bb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ConverterDependency74994152a44d90efb0bdProvider(rootComponent: parent1(component) as! RootComponent)
}
private class SettingsDependency1ba9e199f1bddeac9850Provider: SettingsDependency {
    var configuration: Configuration {
        return rootComponent.configuration
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->SettingsComponent
private func factory3b338491ae548e90be9ab3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SettingsDependency1ba9e199f1bddeac9850Provider(rootComponent: parent1(component) as! RootComponent)
}
private class SettingsDependency4f8da790f210a950b23bProvider: SettingsDependency {
    var configuration: Configuration {
        return rootComponent.configuration
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->UpdateIntervalComponent
private func factory1e882979d313fd93fd9ab3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SettingsDependency4f8da790f210a950b23bProvider(rootComponent: parent1(component) as! RootComponent)
}

#else
extension RootComponent: Registration {
    public func registerItems() {


    }
}
extension ConverterComponent: Registration {
    public func registerItems() {
        keyPathToName[\ConverterDependency.configuration] = "configuration-Configuration"
        keyPathToName[\ConverterDependency.store] = "store-Store"
    }
}
extension SettingsComponent: Registration {
    public func registerItems() {
        keyPathToName[\SettingsDependency.configuration] = "configuration-Configuration"
    }
}
extension UpdateIntervalComponent: Registration {
    public func registerItems() {
        keyPathToName[\SettingsDependency.configuration] = "configuration-Configuration"
    }
}


#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

@inline(never) private func register1() {
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->ConverterComponent", factorybea2fe96e50ead89d19bb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->SettingsComponent", factory3b338491ae548e90be9ab3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->UpdateIntervalComponent", factory1e882979d313fd93fd9ab3a8f24c1d289f2c0f2e)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
