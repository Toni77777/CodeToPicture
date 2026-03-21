import SwiftUI

@Observable
@MainActor
final class AppSettings {
    var selectedThemeID: String = "dracula" {
        didSet { UserDefaults.standard.set(selectedThemeID, forKey: "selectedThemeID") }
    }
    var fontSize: Double = 14 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    var padding: Double = 32 {
        didSet { UserDefaults.standard.set(padding, forKey: "padding") }
    }
    var cornerRadius: Double = 10 {
        didSet { UserDefaults.standard.set(cornerRadius, forKey: "cornerRadius") }
    }
    var showLineNumbers: Bool = true {
        didSet { UserDefaults.standard.set(showLineNumbers, forKey: "showLineNumbers") }
    }
    var showWindowFrame: Bool = true {
        didSet { UserDefaults.standard.set(showWindowFrame, forKey: "showWindowFrame") }
    }
    var backgroundColorHex: String = "#1e1e2e" {
        didSet { UserDefaults.standard.set(backgroundColorHex, forKey: "backgroundHex") }
    }
    var fontFamily: String = "SF Mono" {
        didSet { UserDefaults.standard.set(fontFamily, forKey: "fontFamily") }
    }
    var exportScale: Double = 2.0 {
        didSet { UserDefaults.standard.set(exportScale, forKey: "exportScale") }
    }
    var menuBarModeEnabled: Bool = false {
        didSet { UserDefaults.standard.set(menuBarModeEnabled, forKey: "menuBarEnabled") }
    }
    var windowFrameStyle: String = "macos" {
        didSet { UserDefaults.standard.set(windowFrameStyle, forKey: "windowFrameStyle") }
    }
    var hideDockIcon: Bool = false {
        didSet { UserDefaults.standard.set(hideDockIcon, forKey: "hideDockIcon") }
    }
    var aspectRatio: Double? = nil {
        didSet {
            if let aspectRatio {
                UserDefaults.standard.set(aspectRatio, forKey: "aspectRatio")
            } else {
                UserDefaults.standard.removeObject(forKey: "aspectRatio")
            }
        }
    }

    init() {
        let d = UserDefaults.standard
        if let v = d.string(forKey: "selectedThemeID") { selectedThemeID = v }
        if d.object(forKey: "fontSize") != nil { fontSize = d.double(forKey: "fontSize") }
        if d.object(forKey: "padding") != nil { padding = d.double(forKey: "padding") }
        if d.object(forKey: "cornerRadius") != nil { cornerRadius = d.double(forKey: "cornerRadius") }
        if d.object(forKey: "showLineNumbers") != nil { showLineNumbers = d.bool(forKey: "showLineNumbers") }
        if d.object(forKey: "showWindowFrame") != nil { showWindowFrame = d.bool(forKey: "showWindowFrame") }
        if let v = d.string(forKey: "backgroundHex") { backgroundColorHex = v }
        if let v = d.string(forKey: "fontFamily") { fontFamily = v }
        if d.object(forKey: "exportScale") != nil { exportScale = d.double(forKey: "exportScale") }
        if d.object(forKey: "menuBarEnabled") != nil { menuBarModeEnabled = d.bool(forKey: "menuBarEnabled") }
        if let v = d.string(forKey: "windowFrameStyle") { windowFrameStyle = v }
        if d.object(forKey: "hideDockIcon") != nil { hideDockIcon = d.bool(forKey: "hideDockIcon") }
        if d.object(forKey: "aspectRatio") != nil { aspectRatio = d.double(forKey: "aspectRatio") }
    }
}
