import SwiftUI

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal?
    @State private var text: String = ""

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .onAppear {
                text = AppFormatters.decimalString(value)
            }
            .onChange(of: text) { _, newValue in
                value = Decimal(string: newValue.replacingOccurrences(of: ",", with: "."))
            }
            .onChange(of: value) { _, newValue in
                let formatted = AppFormatters.decimalString(newValue)
                if text != formatted, newValue == nil {
                    text = ""
                }
            }
    }
}
