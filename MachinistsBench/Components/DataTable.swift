import SwiftUI

/// A simple data table matching the app's dark theme.
/// Renders a header row followed by data rows using `Catppuccin` surfaces/borders.
struct DataTable: View {
    let columns: [String]
    let rows: [[String]]
    let accent: Accent

    var body: some View {
        VStack(spacing: 1) {
            // Header row
            HStack(spacing: 0) {
                ForEach(columns.indices, id: \.self) { i in
                    Text(columns[i].uppercased())
                        .font(AppFont.mono(10))
                        .foregroundStyle(accent.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
            }
            .background(accent.color.opacity(0.12))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(accent.color.opacity(0.3)),
                alignment: .bottom
            )

            // Data rows
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(columns.indices, id: \.self) { colIndex in
                        Text(colIndex < rows[rowIndex].count ? rows[rowIndex][colIndex] : "")
                            .font(AppFont.mono(13))
                            .foregroundStyle(Catppuccin.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                }
                .background(rowIndex % 2 == 0 ? Catppuccin.surface0 : Catppuccin.mantle)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent.color.opacity(0.25)))
    }
}

#Preview {
    DataTable(
        columns: ["Pass", "Infeed", "Cum. Depth"],
        rows: [
            ["1", "0.0050\"", "0.0050\""],
            ["2", "0.0035\"", "0.0085\""],
            ["3", "0.0028\"", "0.0113\""],
        ],
        accent: .green
    )
    .padding(16)
    .background(Catppuccin.base)
}
