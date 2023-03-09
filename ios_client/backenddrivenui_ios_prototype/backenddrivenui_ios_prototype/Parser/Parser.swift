import Foundation
import SwiftUI

class Environment {
    private var env = [ViewComponent]()
    let userId = UUID().uuidString
    
    private init() {}
    
    static let instance = Environment()
    
    func add(_ vc: ViewComponent) {
        if !env.contains(where: { $0.id == vc.id }) {
            self.env.append(vc)
        }
    }
    
    func clear() {
        self.env.removeAll()
    }
    
    func getById(_ id: String) -> ViewComponent? {
        env.first(where: { $0.id == id })
    }
    
    //Debugging
    func printAll() {
        print(env)
    }
}

extension Environment {
    func imageComponentById(_ id: String) -> ImageComponent? {
        getById(id) as? ImageComponent
    }
    
    func buttonComponentById(_ id: String) -> ButtonComponent? {
        getById(id) as? ButtonComponent
    }
    
    func labelComponentById(_ id: String) -> LabelComponent? {
        getById(id) as? LabelComponent
    }
    
    func textInputComponentById(_ id: String) -> TextInputComponent? {
        getById(id) as? TextInputComponent
    }
    
    func textComponentById(_ id: String) -> TextComponent? {
        getById(id) as? TextComponent
    }
    
    func sliderComponentById(_ id: String) -> SliderComponent? {
        getById(id) as? SliderComponent
    }
    
    func switchComponentById(_ id: String) -> SwitchComponent? {
        getById(id) as? SwitchComponent
    }
    
    func cardComponentById(_ id: String) -> CardComponent? {
        getById(id) as? CardComponent
    }
    
    func modalComponentById(_ id: String) -> ModalComponent? {
        getById(id) as? ModalComponent
    }
    
    func alertComponentById(_ id: String) -> AlertComponent? {
        getById(id) as? AlertComponent
    }
}

class Parser: ObservableObject {
    
    private init() {}
    
    static let instance = Parser()
    
    var inputServer = ServerManager()
    
    @Published var currentView: ViewComponent = EmptyComponent(id: UUID().uuidString, modifier: [])

    func convertViewRepresentable(viewRepresentable: ViewRepresentable) -> ViewComponent {
        switch viewRepresentable.type {
        case "TEXT" where viewRepresentable.text != nil:
            return TextComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text!
            )
        case "IMAGE" where viewRepresentable.imagePath != nil:
            return ImageComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                imagePath: viewRepresentable.imagePath!
            )
        case "BUTTON" where viewRepresentable.action != nil:
            return ButtonComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text!,
                action: viewRepresentable.action!,
                isEnabled: viewRepresentable.isEnabled
            )
        case "LABEL" where viewRepresentable.text != nil && viewRepresentable.icon != nil:
            return LabelComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text!,
                icon: viewRepresentable.icon!
            )
        case "TEXT_INPUT":
            return TextInputComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text,
                validator: viewRepresentable.validator
            )
        case "SLIDER" where viewRepresentable.rangeStart != nil && viewRepresentable.rangeEnd != nil:
            return SliderComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                rangeStart: viewRepresentable.rangeStart!,
                rangeEnd: viewRepresentable.rangeEnd!
            )
        case "SWITCH" where viewRepresentable.text != nil:
            return SwitchComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text!
            )
        case "TABVIEW" where viewRepresentable.tabViews != nil:
            return TabViewComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                tabViews: viewRepresentable.tabViews!.map(parseTabViews)
            )
        case "SPACER": return SpacerComponent(
            id: viewRepresentable.id,
            modifier: convertModifierList(viewRepresentable.modifier)
        )
        case "CARD" where viewRepresentable.text != nil && viewRepresentable.icon != nil && viewRepresentable.children != nil:
            return CardComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                children: viewRepresentable.children!.map(convertViewRepresentable),
                text: viewRepresentable.text!,
                icon: viewRepresentable.icon!
            )
        case "MODAL" where viewRepresentable.children != nil:
            return ModalComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                children: viewRepresentable.children!.map(convertViewRepresentable)
            )
        case "ALERT" where viewRepresentable.text != nil:
            return AlertComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                text: viewRepresentable.text!,
                message: viewRepresentable.message
            )
        case "LIST" where viewRepresentable.children != nil:
            return  ListComponent(
                id: viewRepresentable.id,
                modifier: convertModifierList(viewRepresentable.modifier),
                children: viewRepresentable.children!.map(convertViewRepresentable)
            )
        case "COLUMN" where viewRepresentable.children != nil: return ColumnComponent (
            id: viewRepresentable.id,
            modifier: convertModifierList(viewRepresentable.modifier),
            children: viewRepresentable.children!.map(convertViewRepresentable)
        )
        case "ROW" where viewRepresentable.children != nil: return RowComponent(
            id: viewRepresentable.id,
            modifier: convertModifierList(viewRepresentable.modifier),
            children: viewRepresentable.children!.map(convertViewRepresentable)
        )
        default: return EmptyComponent(id: UUID().uuidString, modifier: [])
        }
    }
    
    
    func parseTabViews(tabView: ServerTabView) -> ParsedTabView {
        return ParsedTabView(name: tabView.name, icon: tabView.icon, view: convertViewRepresentable(viewRepresentable: tabView.view))
    }
    
    
    func convertModifierList(_ modifier: [ModifierRepresentable]?) -> [ModifierComponent] {
        if(modifier == nil) {
            return []
        } else {
            return modifier!.map(convertModifierRepresentable)
        }
    }
    
    func convertModifierRepresentable(modifierRepresentable: ModifierRepresentable) -> ModifierComponent {
        switch modifierRepresentable.type {
        case "FOREGROUND_COLOR" where modifierRepresentable.color != nil:
            return ForegroundColorModifier(
                type: modifierRepresentable.type,
                color: modifierRepresentable.color!
            )
        case "BACKGROUND_COLOR" where modifierRepresentable.color != nil:
            return BackgroundColorModifier(
                type: modifierRepresentable.type,
                color: modifierRepresentable.color!
            )
        case "FONTSIZE" where modifierRepresentable.fontSize != nil:
            return FondSizeModifier(fontSize: modifierRepresentable.fontSize!)
        case "FONTSTYLE" where modifierRepresentable.fontStyle != nil:
            return FondStyleModifier(fontStyle: modifierRepresentable.fontStyle!)
        case "PADDING": return PaddingModifier()
        case "SIZE" where modifierRepresentable.width != nil: return SizeModifier(width: modifierRepresentable.width!, height: modifierRepresentable.height)
        case "BORDER":
            return BorderModifier(
                color: modifierRepresentable.color,
                width: modifierRepresentable.borderWidth
            )
        case "SHADOW":
            return ShadowModifier(
                color: modifierRepresentable.color,
                radius: modifierRepresentable.radius,
                x: modifierRepresentable.x,
                y: modifierRepresentable.y
            )
        case "SHAPE" where modifierRepresentable.shape != nil:
            return ShapeModifier(
                shape: modifierRepresentable.shape!,
                radius: modifierRepresentable.radius,
                stroke: modifierRepresentable.stroke,
                color: modifierRepresentable.color
            )
        case "CLICKABLE" where modifierRepresentable.action != nil:
            return ClickableModifier(action: modifierRepresentable.action!)
        default: return EmptyModifier()
        }
    }
    
    func resetCurrentView(){
        currentView = TextComponent(id: UUID().uuidString, modifier: [], text: "Platzhalter Text")
    }
    
    func loadScreen(_ screenName: String) async {
        let serverInput = await inputServer.loadScreenFromServer(screenName)
        currentView = convertViewRepresentable(viewRepresentable: serverInput)
    }
    
    func requestWithPayloadAndUiChanges(url: String, payload: [ComponentPayload]) async {
        let uiChanges = await inputServer.sendPayloadGetUiChanges(url: url, payload: payload)
        doChanges(changes: uiChanges.changes)
    }
    
    func requestWithPayloadAndScreenChange(url: String, payload: [ComponentPayload]) async {
        let newScreen = await inputServer.sendPayloadGetNewScreen(url: url, payload: payload)
        currentView = convertViewRepresentable(viewRepresentable: newScreen)
    }
    
    func doChanges(changes: [FieldValue]) {
        changes.forEach { change in
            switch change.type {
            case "IMAGE":
                let component = Environment.instance.imageComponentById(change.id)
                component?.imagePath = change.value
            case "BUTTON":
                let component = Environment.instance.buttonComponentById(change.id)
                switch change.fieldName {
                    case "isActive":
                        component?.isEnabled = Bool(change.value) ?? false
                    case "text":
                        component?.text = change.value
                    default: break
                }
            case "LABEL":
                let component = Environment.instance.labelComponentById(change.id)
                switch change.fieldName {
                    case "text":
                    component?.text = change.value
                    case "icon":
                        component?.icon = change.value
                    default: break
                }
            case "TEXT":
                let component = Environment.instance.textComponentById(change.id)
                component?.text = change.value
            case "CARD":
                let component = Environment.instance.cardComponentById(change.id)
                switch change.fieldName {
                    case "text":
                        component?.text = change.value
                    case "icon":
                        component?.icon = change.value
                    default: break
                }
            case "MODAL":
                let component = Environment.instance.modalComponentById(change.id)
                switch change.fieldName {
                    case "isPresented":
                        component?.isPresented = Bool(change.value) ?? false
                    default: break
                }
            case "ALERT":
                let component = Environment.instance.alertComponentById(change.id)
                switch change.fieldName {
                    case "isPresented":
                        component?.isPresented = Bool(change.value) ?? false
                    default: break
                }
            default: break
            }
        }
    }
}



func getColorFromString(color: String?) -> Color {
    switch color {
    case "RED": return .red
    case "BLUE": return .blue
    case "GREEN": return .green
    case "YELLOW": return .yellow
    case "BLACK": return .black
    default: return .black
    }
}

struct ParsedTabView {
    let name: String
    let icon: String
    let view: ViewComponent
}

struct ClickAction: Codable {
    let type: String
    var destination: String? = nil
    var payloadRequirements: [PayloadRequirement]? = nil
    var checkedFields: [FieldValue]? = nil
    var fieldChanges: [FieldValue]? = nil
}

struct PayloadRequirement: Codable {
    let id: String
    let type: String
}
