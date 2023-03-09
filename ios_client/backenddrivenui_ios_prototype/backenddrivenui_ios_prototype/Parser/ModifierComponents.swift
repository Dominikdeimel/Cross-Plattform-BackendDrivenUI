import Foundation
import SwiftUI


protocol ModifierComponent {
    var id: String { get }
    var type: String { get }
    func render(view: AnyView) -> AnyView
}

struct ForegroundColorModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "FOREGROUND_COLOR"
    let color: String
    
    func render(view: AnyView) -> AnyView {
        return AnyView(view.foregroundColor(getColorFromString(color: color)))
    }
}

struct BackgroundColorModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "BACKGROUND_COLOR"
    let color: String
    
    func render(view: AnyView) -> AnyView {
        return AnyView(view.background(getColorFromString(color: color)))
    }
}

struct FondSizeModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "FONTSIZE"
    let fontSize: Int
    
    func render(view: AnyView) -> AnyView {
        return AnyView(view.font(.system(size: CGFloat(fontSize))))
    }
}

struct FondStyleModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "FONTSTYLE"
    let fontStyle: String
    
    func render(view: AnyView) -> AnyView {
        switch fontStyle {
        case "BOLD": return AnyView(view.bold())
        case "ITALIC": return AnyView(view.italic())
        case "UNDERLINE": return AnyView(view.underline())
        default: return view
        }
    }
}

struct BorderModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "BORDER"
    let color: String?
    let width: Int?
    
    func render(view: AnyView) -> AnyView {
        let widthAsFloat = CGFloat(width ?? 1)
        return AnyView(view.border(getColorFromString(color: color), width: widthAsFloat))
    }
}

struct ShadowModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "SHADOW"
    let color: String?
    let radius: Int?
    let x: Int?
    let y: Int?
    
    func render(view: AnyView) -> AnyView {
        return AnyView(
            view.shadow(
                color: getColorFromString(color: color),
                radius: CGFloat(radius ?? 10),
                x: CGFloat(x ?? 5),
                y: CGFloat(y ?? 5)
            )
        )
    }
}

struct ShapeModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "SHAPE"
    let shape: String
    var radius: Int?
    var stroke: Int?
    var color: String?
    
    func render(view: AnyView) -> AnyView {
        
        switch shape {
        case "CIRCLE": return AnyView(view.clipShape(Circle()).overlay(Circle().stroke(getColorFromString(color: color), lineWidth: CGFloat(stroke ?? 0))))
        case "RECTANGLE": return AnyView(view.clipShape(Rectangle()).overlay(Rectangle().stroke(getColorFromString(color: color), lineWidth: CGFloat(stroke ?? 0))))
        case "ROUNDED_RECTANGLE": return AnyView(view.clipShape(RoundedRectangle(cornerRadius: CGFloat(radius ?? 25))).overlay(RoundedRectangle(cornerRadius: CGFloat(radius ?? 25)).stroke(getColorFromString(color: color), lineWidth: CGFloat(stroke ?? 0))))
        case "CAPSULE": return AnyView(view.clipShape(Capsule()).overlay(Capsule().stroke(getColorFromString(color: color), lineWidth: CGFloat(stroke ?? 0))))
        case "ELLIPSE": return AnyView(view.clipShape(Ellipse()).overlay(Ellipse().stroke(getColorFromString(color: color), lineWidth: CGFloat(stroke ?? 0))))
        default: return view
        }
    }
}

struct PaddingModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "PADDING"
    
    func render(view: AnyView) -> AnyView {
        return AnyView(view.padding())
    }
}

struct SizeModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "SIZE"
    let width: Int
    let height: Int?
    
    func render(view: AnyView) -> AnyView {
        return AnyView(view.frame(width: CGFloat(width), height: (CGFloat(height ?? width))))
    }
}

struct ClickableModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "CLICKABLE"
    let action: ClickAction
    
    func render(view: AnyView)  -> AnyView {
        switch action.type {
        case "NAVIGATION" where action.destination != nil:
            return AnyView(
                view.onTapGesture {
                    Task {
                        do {
                            await Parser.instance.loadScreen(action.destination!)
                        }
                    }
                }
            )
        default: return view
        }
    }
}

struct EmptyModifier: ModifierComponent {
    var id: String = UUID().uuidString
    var type: String = "EMPTY"
    func render(view: AnyView) -> AnyView {
        return view
    }
}
