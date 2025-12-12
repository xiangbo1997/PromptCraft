import Foundation

let colors: [String: (light: String, dark: String)] = [
    "Primary": ("#007AFF", "#0A84FF"),
    "PrimaryHover": ("#0051D5", "#409CFF"),
    "PrimaryPressed": ("#004DB3", "#66B3FF"),
    "Secondary": ("#5856D6", "#5E5CE6"),
    "Success": ("#34C759", "#32D74B"),
    "Warning": ("#FF9500", "#FF9F0A"),
    "Error": ("#FF3B30", "#FF453A"),
    "Background": ("#FFFFFF", "#1C1C1E"),
    "Surface": ("#F5F5F7", "#2C2C2E"),
    "Border": ("#E5E5EA", "#38383A"),
    "Divider": ("#D1D1D6", "#48484A"),
    "TextPrimary": ("#000000", "#FFFFFF"),
    "TextSecondary": ("#3C3C4399", "#EBEBF599"), // 60% opacity
    "TextTertiary": ("#3C3C434D", "#EBEBF54D"), // 30% opacity
    "TextDisabled": ("#3C3C432E", "#EBEBF52E"), // 18% opacity
    "InfoBackground": ("#007AFF1A", "#007AFF1A"), // 10% opacity
    "SuccessBackground": ("#34C7591A", "#34C7591A"),
    "WarningBackground": ("#FF95001A", "#FF95001A"),
    "ErrorBackground": ("#FF3B301A", "#FF3B301A")
]

func hexToComponents(_ hex: String) -> [String: String] {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let r, g, b, a: Double
    if hexSanitized.count == 8 {
        r = Double((rgb & 0xFF000000) >> 24) / 255.0
        g = Double((rgb & 0x00FF0000) >> 16) / 255.0
        b = Double((rgb & 0x0000FF00) >> 8) / 255.0
        a = Double(rgb & 0x000000FF) / 255.0
    } else {
        r = Double((rgb & 0xFF0000) >> 16) / 255.0
        g = Double((rgb & 0x00FF00) >> 8) / 255.0
        b = Double(rgb & 0x0000FF) / 255.0
        a = 1.0
    }

    return [
        "red": String(format: "%.3f", r),
        "green": String(format: "%.3f", g),
        "blue": String(format: "%.3f", b),
        "alpha": String(format: "%.3f", a)
    ]
}

let fileManager = FileManager.default
let basePath = "PromptCraft/Resources/Assets.xcassets"

try? fileManager.createDirectory(atPath: basePath, withIntermediateDirectories: true)

// Create Contents.json for root
let rootContents = """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try? rootContents.write(toFile: "\(basePath)/Contents.json", atomically: true, encoding: .utf8)

for (name, values) in colors {
    let colorSetPath = "\(basePath)/\(name).colorset"
    try? fileManager.createDirectory(atPath: colorSetPath, withIntermediateDirectories: true)
    
    let lightComponents = hexToComponents(values.light)
    let darkComponents = hexToComponents(values.dark)
    
    let jsonContent = """
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "\(lightComponents["alpha"]!)",
          "blue" : "\(lightComponents["blue"]!)",
          "green" : "\(lightComponents["green"]!)",
          "red" : "\(lightComponents["red"]!)"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "\(darkComponents["alpha"]!)",
          "blue" : "\(darkComponents["blue"]!)",
          "green" : "\(darkComponents["green"]!)",
          "red" : "\(darkComponents["red"]!)"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
    try? jsonContent.write(toFile: "\(colorSetPath)/Contents.json", atomically: true, encoding: .utf8)
}

print("Assets generated successfully!")
