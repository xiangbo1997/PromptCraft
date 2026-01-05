import Foundation

// MARK: - 场景分类
/// 场景分类枚举，定义不同的使用场景
enum SceneCategory: String, Codable, CaseIterable, Identifiable {
    case xiaohongshu = "xiaohongshu"     // 小红书运营
    case workplace = "workplace"          // 职场效率
    case programming = "programming"      // 编程辅助
    case marketing = "marketing"          // 营销文案
    case education = "education"          // 教育学习
    case creative = "creative"            // 创意写作

    var id: String { rawValue }

    /// 本地化键名
    var localizationKey: String {
        "scene.category.\(rawValue)"
    }

    /// 本地化描述键名
    var descriptionKey: String {
        "scene.category.\(rawValue).description"
    }

    /// 分类显示名称（本地化）
    @MainActor
    var displayName: String {
        LocalizationService.shared.l(localizationKey)
    }

    /// 分类图标
    var icon: String {
        switch self {
        case .xiaohongshu: return "heart.text.square"
        case .workplace: return "briefcase"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        case .marketing: return "megaphone"
        case .education: return "book"
        case .creative: return "paintbrush"
        }
    }

    /// 分类颜色（十六进制）
    var colorHex: String {
        switch self {
        case .xiaohongshu: return "FF2442"  // 小红书红
        case .workplace: return "2563EB"    // 职场蓝
        case .programming: return "10B981"  // 编程绿
        case .marketing: return "F59E0B"    // 营销橙
        case .education: return "8B5CF6"    // 教育紫
        case .creative: return "EC4899"     // 创意粉
        }
    }

    /// 分类描述（本地化）
    @MainActor
    var description: String {
        LocalizationService.shared.l(descriptionKey)
    }
}

// MARK: - 模板字段类型
/// 模板中的输入字段类型
enum TemplateFieldType: String, Codable {
    case text           // 单行文本
    case textarea       // 多行文本
    case select         // 下拉选择
    case multiSelect    // 多选
    case number         // 数字
    case toggle         // 开关
}

// MARK: - 模板字段
/// 模板中的单个输入字段定义
struct TemplateField: Codable, Identifiable, Hashable {
    let id: String
    let labelKey: String           // 字段标签本地化键
    let placeholderKey: String     // 占位提示本地化键
    let fieldType: TemplateFieldType
    let isRequired: Bool           // 是否必填
    let optionKeys: [String]?      // 选择类型的选项本地化键
    let defaultValueKey: String?   // 默认值本地化键
    let maxLength: Int?            // 最大长度限制

    /// 本地化后的标签
    @MainActor
    var label: String {
        LocalizationService.shared.l(labelKey)
    }

    /// 本地化后的占位提示
    @MainActor
    var placeholder: String {
        LocalizationService.shared.l(placeholderKey)
    }

    /// 本地化后的选项
    @MainActor
    var options: [String]? {
        optionKeys?.map { LocalizationService.shared.l($0) }
    }

    /// 本地化后的默认值
    @MainActor
    var defaultValue: String? {
        guard let key = defaultValueKey else { return nil }
        return LocalizationService.shared.l(key)
    }

    init(
        id: String,
        labelKey: String,
        placeholderKey: String = "",
        fieldType: TemplateFieldType = .text,
        isRequired: Bool = true,
        optionKeys: [String]? = nil,
        defaultValueKey: String? = nil,
        maxLength: Int? = nil
    ) {
        self.id = id
        self.labelKey = labelKey
        self.placeholderKey = placeholderKey
        self.fieldType = fieldType
        self.isRequired = isRequired
        self.optionKeys = optionKeys
        self.defaultValueKey = defaultValueKey
        self.maxLength = maxLength
    }
}

// MARK: - 场景模板
/// 场景模板定义
struct SceneTemplate: Codable, Identifiable, Hashable {
    let id: String
    let nameKey: String                 // 模板名称本地化键
    let category: SceneCategory         // 所属分类
    let descriptionKey: String          // 模板描述本地化键
    let icon: String                    // 模板图标
    let fields: [TemplateField]         // 输入字段
    let systemPromptKey: String         // 系统提示词本地化键
    let userPromptTemplateKey: String   // 用户提示词模板本地化键
    let exampleOutputKey: String?       // 示例输出本地化键（可选）
    let tagKeys: [String]               // 标签本地化键
    let isPremium: Bool                 // 是否为付费模板
    let usageCount: Int                 // 使用次数（统计用）
    let order: Int                      // 排序权重

    /// 本地化后的名称
    @MainActor
    var name: String {
        LocalizationService.shared.l(nameKey)
    }

    /// 本地化后的描述
    @MainActor
    var description: String {
        LocalizationService.shared.l(descriptionKey)
    }

    /// 本地化后的系统提示词
    @MainActor
    var systemPrompt: String {
        LocalizationService.shared.l(systemPromptKey)
    }

    /// 本地化后的用户提示词模板
    @MainActor
    var userPromptTemplate: String {
        LocalizationService.shared.l(userPromptTemplateKey)
    }

    /// 本地化后的示例输出
    @MainActor
    var exampleOutput: String? {
        guard let key = exampleOutputKey else { return nil }
        return LocalizationService.shared.l(key)
    }

    /// 本地化后的标签
    @MainActor
    var tags: [String] {
        tagKeys.map { LocalizationService.shared.l($0) }
    }

    init(
        id: String,
        nameKey: String,
        category: SceneCategory,
        descriptionKey: String,
        icon: String,
        fields: [TemplateField],
        systemPromptKey: String,
        userPromptTemplateKey: String,
        exampleOutputKey: String? = nil,
        tagKeys: [String] = [],
        isPremium: Bool = false,
        usageCount: Int = 0,
        order: Int = 0
    ) {
        self.id = id
        self.nameKey = nameKey
        self.category = category
        self.descriptionKey = descriptionKey
        self.icon = icon
        self.fields = fields
        self.systemPromptKey = systemPromptKey
        self.userPromptTemplateKey = userPromptTemplateKey
        self.exampleOutputKey = exampleOutputKey
        self.tagKeys = tagKeys
        self.isPremium = isPremium
        self.usageCount = usageCount
        self.order = order
    }

    /// 根据用户输入生成最终的提示词
    /// - Parameter fieldValues: 字段ID到值的映射
    /// - Returns: 填充后的提示词
    @MainActor
    func generatePrompt(with fieldValues: [String: String]) -> String {
        var result = userPromptTemplate
        for (fieldId, value) in fieldValues {
            result = result.replacingOccurrences(of: "{{\(fieldId)}}", with: value)
        }
        return result
    }

    /// 验证必填字段是否都已填写
    /// - Parameter fieldValues: 字段ID到值的映射
    /// - Returns: 未填写的必填字段列表
    func validateFields(_ fieldValues: [String: String]) -> [TemplateField] {
        return fields.filter { field in
            guard field.isRequired else { return false }
            let value = fieldValues[field.id] ?? ""
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

// MARK: - 用户填写的模板数据
/// 用户填写模板时的临时数据
struct TemplateFormData: Identifiable {
    let id = UUID()
    let template: SceneTemplate
    var fieldValues: [String: String] = [:]

    @MainActor
    init(template: SceneTemplate) {
        self.template = template
        // 初始化默认值
        for field in template.fields {
            if let defaultValue = field.defaultValue {
                fieldValues[field.id] = defaultValue
            }
        }
    }

    /// 获取生成的提示词
    @MainActor
    var generatedPrompt: String {
        template.generatePrompt(with: fieldValues)
    }

    /// 验证表单是否有效
    var isValid: Bool {
        template.validateFields(fieldValues).isEmpty
    }

    /// 获取未填写的必填字段
    var missingFields: [TemplateField] {
        template.validateFields(fieldValues)
    }
}
