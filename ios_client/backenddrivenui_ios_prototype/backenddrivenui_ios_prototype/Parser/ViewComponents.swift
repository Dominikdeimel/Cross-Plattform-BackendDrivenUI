import Foundation
import SwiftUI

protocol ViewComponent {
    var id: String { get }
    var permittedModifier: [String] { get }
    var modifier: [ModifierComponent] { get }
    
    func generateBaseView() -> AnyView
}



extension ViewComponent {
    func render() -> AnyView {
        Environment.instance.add(self)
        return applyModifier(baseView: generateBaseView())
    }
    
    func applyModifier(baseView: AnyView) -> AnyView {
        let filteredModifier = modifier.filter({permittedModifier.contains($0.type)})
        if(filteredModifier.isEmpty){
            return baseView
        } else {
            return filteredModifier.reduce(baseView){ view, mod in
                mod.render(view: view)
            }
        }
    }
}

class AlertComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = []
    var modifier: [ModifierComponent] = []
    
    @Published var isPresented = false
    @Published var text = ""
    @Published var message = ""
    
    init(id: String, modifier: [ModifierComponent], text: String, message: String?) {
        self.id = id
        self.modifier = modifier
        self.text = text
        self.message = message ?? ""
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_AlertComponent(alertComponent: self))
    }
    
    struct _AlertComponent: View {
        @ObservedObject var alertComponent: AlertComponent
        
        var body: some View {
            VStack{}.alert(isPresented: $alertComponent.isPresented) {
                Alert(title: Text(alertComponent.text), message: Text(alertComponent.message), dismissButton: .default(Text("Ok")))
            }
        }
    }
}

class ModalComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = []
    var modifier: [ModifierComponent] = []
    var children: [ViewComponent]
    
    @Published var isPresented = false
    
    init(id: String, modifier: [ModifierComponent], children: [ViewComponent]) {
        self.id = id
        self.modifier = modifier
        self.children = children
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_ModalComponent(modalComponent: self))
    }
    
    struct _ModalComponent: View {
        @ObservedObject var modalComponent: ModalComponent
        
        var body: some View {
            VStack{}.sheet(isPresented: $modalComponent.isPresented){
                ForEach(modalComponent.children, id: \.id){ child in
                    child.render()
                }            }
        }
    }
}

class ImageComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["PADDING", "SIZE", "BORDER", "SHADOW", "SHAPE"]
    var modifier: [ModifierComponent] = []
    @Published var imagePath: String = ""
    
    init(id: String, modifier: [ModifierComponent], imagePath: String){
        self.id = id
        self.modifier = modifier
        self.imagePath = imagePath
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_ImageComponent(imageComponent: self))
    }
    
    struct _ImageComponent: View {
        @ObservedObject var imageComponent: ImageComponent
        
        var body: some View {
            Image(imageComponent.imagePath).resizable()
        }
    }
}

class ButtonComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "PADDING", "SIZE", "BORDER", "SHADOW", "SHAPE","CLICKABLE"]
    var modifier: [ModifierComponent] = []
    let action: ClickAction
    
    @Published var text = ""
    @Published var isEnabled = true

    init(id: String, modifier: [ModifierComponent], text: String?, action: ClickAction, isEnabled: Bool?) {
        self.id = id
        self.modifier = modifier
        self.text = text ?? ""
        self.action = action
        self.isEnabled = isEnabled ?? true
    }
    
    struct _ButtonComponent: View {
        @ObservedObject var buttonComponent: ButtonComponent
        
        var body: some View {
            Button(buttonComponent.text){
                doAction()
                
            }.disabled(!buttonComponent.isEnabled)
        }
        
        func doAction() {
            switch buttonComponent.action.type {
            case "REQUEST_WITH_SCREEN_CHANGE" where buttonComponent.action.destination != nil:
                    Task {
                        do {
                            await Parser.instance.loadScreen(buttonComponent.action.destination!)
                        }
                    }
            case "REQUEST_WITH_PAYLOAD_AND_UI_CHANGES" where buttonComponent.action.destination != nil && buttonComponent.action.payloadRequirements != nil:
                let payload = generatePayload(buttonComponent.action.payloadRequirements!)
                    Task {
                        do {
                            await Parser.instance.requestWithPayloadAndUiChanges(url: buttonComponent.action.destination!, payload: payload)
                        }
                    }
            case "REQUEST_WITH_PAYLOAD_AND_SCREEN_CHANGE" where buttonComponent.action.destination != nil && buttonComponent.action.payloadRequirements != nil:
                let payload = generatePayload(buttonComponent.action.payloadRequirements!)
                    Task {
                        do {
                            await Parser.instance.requestWithPayloadAndScreenChange(url: buttonComponent.action.destination!, payload: payload)
                        }
                    }
            case "CHECK_WITH_UI_CHANGES" where buttonComponent.action.checkedFields != nil && buttonComponent.action.fieldChanges != nil:
                let checkFields = buttonComponent.action.checkedFields!.allSatisfy { fieldValue in
                    switch fieldValue.type {
                    case "TEXT_INPUT":
                        let textInput = Environment.instance.textInputComponentById(fieldValue.id)
                        switch fieldValue.fieldName {
                            case "isValid":
                                return textInput?.isValid.description == fieldValue.value
                            default: return false
                        }
                    default: return false
                    }
                }
                if(checkFields){
                    Parser.instance.doChanges(changes: buttonComponent.action.fieldChanges!)
                }
            case "UI_CHANGES" where buttonComponent.action.fieldChanges != nil:
                Parser.instance.doChanges(changes: buttonComponent.action.fieldChanges!)
            case "TRIGGER_MODAL" where buttonComponent.action.destination != nil:
                let fieldValue = FieldValue(id: buttonComponent.action.destination!, type: "MODAL", fieldName: "isPresented", value: "true")
                Parser.instance.doChanges(changes: [fieldValue])
            case "TRIGGER_ALERT" where buttonComponent.action.destination != nil:
                let fieldValue = FieldValue(id: buttonComponent.action.destination!, type: "ALERT", fieldName: "isPresented", value: "true")
                Parser.instance.doChanges(changes: [fieldValue])
            default: break
            }
        }
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_ButtonComponent(buttonComponent: self))
    }
    
    
}

func generatePayload(_ payloadRequirements: [PayloadRequirement]) -> [ComponentPayload] {
    var payload = [ComponentPayload]()
    payloadRequirements.forEach { pReq in
        switch pReq.type {
        case "TEXT_INPUT":
            let requiredComponent = Environment.instance.textInputComponentById(pReq.id)
            payload.append(ComponentPayload(
                id: pReq.id,
                type: pReq.type,
                payload: [ComponentFieldValue(fieldName: "text", value: requiredComponent?.input.description ?? "Missing Component!")
                ]
            ))
        default: break
        }
    }
    return payload
}

class LabelComponent: ViewComponent, ObservableObject {
    let id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "FONTSIZE", "FONTSTYLE", "PADDING", "BORDER", "SHADOW"]
    var modifier: [ModifierComponent] = []
    
    @Published var text: String
    @Published var icon: String
    
    init(id: String, modifier: [ModifierComponent], text: String, icon: String){
        self.id = id
        self.modifier = modifier
        self.text = text
        self.icon = icon
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_LabelComponent(labelComponent: self))
    }
    
    struct _LabelComponent: View {
        @ObservedObject var labelComponent: LabelComponent
        
        var body: some View {
            Label(labelComponent.text, systemImage: labelComponent.icon)
        }
    }
}

class TextComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "FONTSIZE", "FONTSTYLE", "PADDING", "BORDER", "SHADOW"]
    var modifier: [ModifierComponent] = []
    @Published var text = ""
    
    init(id: String, modifier: [ModifierComponent], text: String) {
        self.id = id
        self.modifier = modifier
        self.text = text
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_TextComponent(textComponent: self))
    }
    
    struct _TextComponent: View {
        @ObservedObject var textComponent: TextComponent
        
        var body: some View {
            Text(textComponent.text)
        }
    }
}


class TextInputComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "FONTSIZE", "FONTSTYLE", "PADDING", "BORDER", "SHADOW"]
    var modifier: [ModifierComponent] = []
    let validator: Validator?
    let text: String?
    
    @Published var isValid = false
    @Published var input = ""
    
    init(id: String, modifier: [ModifierComponent], text: String?, validator: Validator?) {
        self.id = id
        self.modifier = modifier
        self.text = text
        self.validator = validator
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_TextInputComponent(textInputComponent: self))
    }
    
    struct _TextInputComponent: View {
        @ObservedObject var textInputComponent: TextInputComponent
        
        var body: some View {
            let binding = Binding<String>(get: {
                textInputComponent.input
                    }, set: {
                        textInputComponent.input = $0
                        if( textInputComponent.validator != nil){
                            textInputComponent.isValid = validInput(input: textInputComponent.input, validator: textInputComponent.validator!)
                        }
                    })
            
            TextField(textInputComponent.text ?? "", text: binding)
            
        }
    }
}




class SliderComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["PADDING"]
    var modifier: [ModifierComponent] = []
    let rangeStart: Int
    let rangeEnd: Int
    
    init(id: String, modifier: [ModifierComponent], rangeStart: Int, rangeEnd: Int){
        self.id = id
        self.modifier = modifier
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_SliderComponent(sliderComponent: self))
    }
    
    struct _SliderComponent: View {
        @ObservedObject var sliderComponent: SliderComponent
        @State var sliderValue = 0.0
        
        var body: some View {
            VStack {
                Text("SliderValue: \(sliderValue)")
                Slider(value: $sliderValue, in: Double(sliderComponent.rangeStart)...Double(sliderComponent.rangeEnd))
            }
        }
    }
}


class SwitchComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["PADDING"]
    var modifier: [ModifierComponent] = []
    @Published var text: String
    @Published var isOn = false
    
    init(id: String, modifier: [ModifierComponent], text: String){
        self.id = id
        self.modifier = modifier
        self.text = text
    }
        
    func generateBaseView() -> AnyView {
        return AnyView(_SwitchComponent(switchComponent: self))
    }
    
    struct _SwitchComponent: View {
        @ObservedObject var switchComponent: SwitchComponent

        var body: some View {
            VStack{
                Text("isOn: \(switchComponent.isOn.description)")
                Toggle(switchComponent.text, isOn: $switchComponent.isOn)
            }
        }
    }
}

class TabViewComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = []
    var modifier: [ModifierComponent] = []
    let tabViews: [ParsedTabView]
    
    init(id: String, modifier: [ModifierComponent], tabViews: [ParsedTabView]){
        self.id = id
        self.modifier = modifier
        self.tabViews = tabViews
    }
    
    
    func generateBaseView() -> AnyView {
        AnyView(_TabViewComponent(tabViewComponent: self))
    }
    
    struct _TabViewComponent: View {
        @ObservedObject var tabViewComponent: TabViewComponent
        
        var body: some View {
            TabView{
                ForEach(tabViewComponent.tabViews, id: \.name){ tabView in
                    tabView.view.render().tabItem {
                        Label(tabView.name, systemImage: tabView.icon)
                    }
                }
            }
        }
    }
}

class CardComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["PADDING"]
    var modifier: [ModifierComponent]
    let children: [ViewComponent]
    @Published var text: String
    @Published var icon: String
    
    init(id: String, modifier: [ModifierComponent], children: [ViewComponent], text: String, icon: String){
        self.id = id
        self.modifier = modifier
        self.children = children
        self.text = text
        self.icon = icon
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_CardComponent(cardComponent: self))
    }
    
    struct _CardComponent: View {
        @ObservedObject var cardComponent: CardComponent
        
        var body: some View {
            GroupBox(label: Label(cardComponent.text, systemImage: cardComponent.icon)) {
                ForEach(cardComponent.children, id: \.id){ child in
                    child.render()
                }
            }
        }
    }
}

class SpacerComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "PADDING", "BORDER"]
    var modifier: [ModifierComponent] = []
    
    init(id: String, modifier: [ModifierComponent]){
        self.id = id
        self.modifier = modifier
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_SpacerComponent(spacerComponent: self))
    }
    
    struct _SpacerComponent: View {
        @ObservedObject var spacerComponent: SpacerComponent
        
        var body: some View {
            Spacer()
        }
    }
}

class ListComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "PADDING"]
    var modifier: [ModifierComponent] = []
    let children: [ViewComponent]
    
    init(id: String, modifier: [ModifierComponent], children: [ViewComponent]){
        self.id = id
        self.modifier = modifier
        self.children = children
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_ListComponent(listComponent: self))
    }
    
    struct _ListComponent: View {
        @ObservedObject var listComponent: ListComponent
        
        var body: some View {
            List {
                ForEach(listComponent.children, id: \.id){ item in
                    item.render()
                }
            }
        }
    }
}

class ColumnComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "PADDING", "BORDER"]
    var modifier: [ModifierComponent] = []
    let children: [ViewComponent]
    
    init(id: String, modifier: [ModifierComponent], children: [ViewComponent]){
        self.id = id
        self.modifier = modifier
        self.children = children
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_ColumnComponent(columnComponent: self))
    }
    
    struct _ColumnComponent: View {
        @ObservedObject var columnComponent: ColumnComponent
        
        var body: some View {
            VStack {
                ForEach(columnComponent.children, id: \.id){ child in
                    child.render()
                }
            }
        }
    }
}

class RowComponent: ViewComponent, ObservableObject {
    var id: String
    var permittedModifier: [String] = ["FOREGROUND_COLOR", "BACKGROUND_COLOR", "PADDING", "BORDER"]
    var modifier: [ModifierComponent] = []
    let children: [ViewComponent]
    
    init(id: String, modifier: [ModifierComponent], children: [ViewComponent]){
        self.id = id
        self.modifier = modifier
        self.children = children
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_RowComponent(rowComponent: self))
    }
    
    struct _RowComponent: View {
        @ObservedObject var rowComponent: RowComponent
        
        var body: some View {
            HStack {
                ForEach(rowComponent.children, id: \.id){ child in
                    child.render()
                }
            }
        }
    }
}

class EmptyComponent: ViewComponent, ObservableObject {
    var id: String = UUID().uuidString
    var permittedModifier: [String] = []
    var modifier: [ModifierComponent] = []
    
    init(id: String, modifier: [ModifierComponent]){
        self.id = id
        self.modifier = modifier
    }
    
    func generateBaseView() -> AnyView {
        return AnyView(_EmptyComponent(emptyComponent: self))
    }
    
    struct _EmptyComponent: View {
        @ObservedObject var emptyComponent: EmptyComponent
        
        var body: some View {
            EmptyView()
        }
    }
}

func validInput(input: String, validator: Validator) -> Bool {
    switch validator.type {
    case "REGEX":
        guard let gRegex = try? NSRegularExpression(pattern: validator.value) else {
                    return false
                }
                
        let range = NSRange(location: 0, length: input.utf16.count)
        if gRegex.firstMatch(in: input, options: [], range: range) != nil {
            return true
        }
                
                return false
    
    default: return false
    }
}
