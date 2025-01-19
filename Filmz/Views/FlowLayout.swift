import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for row in result.rows {
            for item in row {
                let position = CGPoint(
                    x: bounds.minX + item.x,
                    y: bounds.minY + item.y
                )
                
                item.subview.place(
                    at: position,
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }
    
    struct FlowResult {
        var height: CGFloat = 0
        var rows: [[Item]] = []
        
        struct Item {
            let subview: LayoutSubview
            var size: CGSize
            var x: CGFloat
            var y: CGFloat
        }
        
        init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var rows: [[Item]] = []
            var currentRow: [Item] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    currentRow = []
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                currentRow.append(Item(subview: subview, size: size, x: x, y: y))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                y += rowHeight
            }
            
            self.rows = rows
            self.height = y
        }
    }
} 