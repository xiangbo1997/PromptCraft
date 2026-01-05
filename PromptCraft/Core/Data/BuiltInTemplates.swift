import Foundation

// MARK: - 内置模板数据
/// 预置的场景模板，用户开箱即用
enum BuiltInTemplates {

    // MARK: - 获取所有内置模板
    static var all: [SceneTemplate] {
        return xiaohongshuTemplates + workplaceTemplates + programmingTemplates + marketingTemplates + educationTemplates + creativeTemplates
    }

    // MARK: - 按分类获取
    static func templates(for category: SceneCategory) -> [SceneTemplate] {
        switch category {
        case .xiaohongshu: return xiaohongshuTemplates
        case .workplace: return workplaceTemplates
        case .programming: return programmingTemplates
        case .marketing: return marketingTemplates
        case .education: return educationTemplates
        case .creative: return creativeTemplates
        }
    }

    // MARK: - 小红书运营模板
    static let xiaohongshuTemplates: [SceneTemplate] = [
        // 爆款标题生成
        SceneTemplate(
            id: "xhs_title",
            nameKey: "template.xhs_title.name",
            category: .xiaohongshu,
            descriptionKey: "template.xhs_title.description",
            icon: "sparkles",
            fields: [
                TemplateField(
                    id: "product",
                    labelKey: "template.xhs_title.field.product.label",
                    placeholderKey: "template.xhs_title.field.product.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "selling_point",
                    labelKey: "template.xhs_title.field.selling_point.label",
                    placeholderKey: "template.xhs_title.field.selling_point.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "style",
                    labelKey: "template.xhs_title.field.style.label",
                    placeholderKey: "template.xhs_title.field.style.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.xhs_title.field.style.option.recommend",
                        "template.xhs_title.field.style.option.review",
                        "template.xhs_title.field.style.option.tutorial",
                        "template.xhs_title.field.style.option.emotional",
                        "template.xhs_title.field.style.option.suspense"
                    ],
                    defaultValueKey: "template.xhs_title.field.style.option.recommend"
                )
            ],
            systemPromptKey: "template.xhs_title.system_prompt",
            userPromptTemplateKey: "template.xhs_title.user_prompt",
            exampleOutputKey: "template.xhs_title.example_output",
            tagKeys: ["template.tag.title", "template.tag.viral", "template.tag.eyecatching"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // 种草文案
        SceneTemplate(
            id: "xhs_recommend",
            nameKey: "template.xhs_recommend.name",
            category: .xiaohongshu,
            descriptionKey: "template.xhs_recommend.description",
            icon: "leaf",
            fields: [
                TemplateField(
                    id: "product_name",
                    labelKey: "template.xhs_recommend.field.product_name.label",
                    placeholderKey: "template.xhs_recommend.field.product_name.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "product_features",
                    labelKey: "template.xhs_recommend.field.product_features.label",
                    placeholderKey: "template.xhs_recommend.field.product_features.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "target_audience",
                    labelKey: "template.xhs_recommend.field.target_audience.label",
                    placeholderKey: "template.xhs_recommend.field.target_audience.placeholder",
                    fieldType: .text,
                    isRequired: false,
                    optionKeys: nil,
                    defaultValueKey: "template.xhs_recommend.field.target_audience.default"
                ),
                TemplateField(
                    id: "price_range",
                    labelKey: "template.xhs_recommend.field.price_range.label",
                    placeholderKey: "template.xhs_recommend.field.price_range.placeholder",
                    fieldType: .text,
                    isRequired: false
                )
            ],
            systemPromptKey: "template.xhs_recommend.system_prompt",
            userPromptTemplateKey: "template.xhs_recommend.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.recommend", "template.tag.copywriting", "template.tag.conversion"],
            isPremium: true,
            usageCount: 0,
            order: 2
        ),

        // 评论区回复
        SceneTemplate(
            id: "xhs_reply",
            nameKey: "template.xhs_reply.name",
            category: .xiaohongshu,
            descriptionKey: "template.xhs_reply.description",
            icon: "bubble.left.and.bubble.right",
            fields: [
                TemplateField(
                    id: "comment_content",
                    labelKey: "template.xhs_reply.field.comment_content.label",
                    placeholderKey: "template.xhs_reply.field.comment_content.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "reply_tone",
                    labelKey: "template.xhs_reply.field.reply_tone.label",
                    placeholderKey: "template.xhs_reply.field.reply_tone.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.xhs_reply.field.reply_tone.option.friendly",
                        "template.xhs_reply.field.reply_tone.option.humorous",
                        "template.xhs_reply.field.reply_tone.option.professional",
                        "template.xhs_reply.field.reply_tone.option.cute"
                    ],
                    defaultValueKey: "template.xhs_reply.field.reply_tone.option.friendly"
                ),
                TemplateField(
                    id: "brand_info",
                    labelKey: "template.xhs_reply.field.brand_info.label",
                    placeholderKey: "template.xhs_reply.field.brand_info.placeholder",
                    fieldType: .text,
                    isRequired: false
                )
            ],
            systemPromptKey: "template.xhs_reply.system_prompt",
            userPromptTemplateKey: "template.xhs_reply.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.comment", "template.tag.interaction", "template.tag.reply"],
            isPremium: true,
            usageCount: 0,
            order: 3
        )
    ]

    // MARK: - 职场效率模板
    static let workplaceTemplates: [SceneTemplate] = [
        // 周报生成
        SceneTemplate(
            id: "work_weekly",
            nameKey: "template.work_weekly.name",
            category: .workplace,
            descriptionKey: "template.work_weekly.description",
            icon: "doc.text",
            fields: [
                TemplateField(
                    id: "work_done",
                    labelKey: "template.work_weekly.field.work_done.label",
                    placeholderKey: "template.work_weekly.field.work_done.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "work_progress",
                    labelKey: "template.work_weekly.field.work_progress.label",
                    placeholderKey: "template.work_weekly.field.work_progress.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "next_week_plan",
                    labelKey: "template.work_weekly.field.next_week_plan.label",
                    placeholderKey: "template.work_weekly.field.next_week_plan.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "problems",
                    labelKey: "template.work_weekly.field.problems.label",
                    placeholderKey: "template.work_weekly.field.problems.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "report_style",
                    labelKey: "template.work_weekly.field.report_style.label",
                    placeholderKey: "template.work_weekly.field.report_style.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.work_weekly.field.report_style.option.concise",
                        "template.work_weekly.field.report_style.option.detailed",
                        "template.work_weekly.field.report_style.option.data_driven"
                    ],
                    defaultValueKey: "template.work_weekly.field.report_style.option.concise"
                )
            ],
            systemPromptKey: "template.work_weekly.system_prompt",
            userPromptTemplateKey: "template.work_weekly.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.weekly_report", "template.tag.report", "template.tag.workplace"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // 邮件润色
        SceneTemplate(
            id: "work_email",
            nameKey: "template.work_email.name",
            category: .workplace,
            descriptionKey: "template.work_email.description",
            icon: "envelope",
            fields: [
                TemplateField(
                    id: "email_purpose",
                    labelKey: "template.work_email.field.email_purpose.label",
                    placeholderKey: "template.work_email.field.email_purpose.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "main_content",
                    labelKey: "template.work_email.field.main_content.label",
                    placeholderKey: "template.work_email.field.main_content.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "recipient",
                    labelKey: "template.work_email.field.recipient.label",
                    placeholderKey: "template.work_email.field.recipient.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.work_email.field.recipient.option.supervisor",
                        "template.work_email.field.recipient.option.client",
                        "template.work_email.field.recipient.option.colleague",
                        "template.work_email.field.recipient.option.subordinate"
                    ],
                    defaultValueKey: "template.work_email.field.recipient.option.supervisor"
                ),
                TemplateField(
                    id: "tone",
                    labelKey: "template.work_email.field.tone.label",
                    placeholderKey: "template.work_email.field.tone.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.work_email.field.tone.option.formal",
                        "template.work_email.field.tone.option.friendly",
                        "template.work_email.field.tone.option.direct"
                    ],
                    defaultValueKey: "template.work_email.field.tone.option.formal"
                )
            ],
            systemPromptKey: "template.work_email.system_prompt",
            userPromptTemplateKey: "template.work_email.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.email", "template.tag.business", "template.tag.communication"],
            isPremium: false,
            usageCount: 0,
            order: 2
        ),

        // 会议纪要
        SceneTemplate(
            id: "work_meeting",
            nameKey: "template.work_meeting.name",
            category: .workplace,
            descriptionKey: "template.work_meeting.description",
            icon: "person.3",
            fields: [
                TemplateField(
                    id: "meeting_topic",
                    labelKey: "template.work_meeting.field.meeting_topic.label",
                    placeholderKey: "template.work_meeting.field.meeting_topic.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "meeting_content",
                    labelKey: "template.work_meeting.field.meeting_content.label",
                    placeholderKey: "template.work_meeting.field.meeting_content.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "participants",
                    labelKey: "template.work_meeting.field.participants.label",
                    placeholderKey: "template.work_meeting.field.participants.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "meeting_date",
                    labelKey: "template.work_meeting.field.meeting_date.label",
                    placeholderKey: "template.work_meeting.field.meeting_date.placeholder",
                    fieldType: .text,
                    isRequired: false
                )
            ],
            systemPromptKey: "template.work_meeting.system_prompt",
            userPromptTemplateKey: "template.work_meeting.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.meeting", "template.tag.minutes", "template.tag.organize"],
            isPremium: false,
            usageCount: 0,
            order: 3
        )
    ]

    // MARK: - 编程辅助模板
    static let programmingTemplates: [SceneTemplate] = [
        // 代码解释
        SceneTemplate(
            id: "code_explain",
            nameKey: "template.code_explain.name",
            category: .programming,
            descriptionKey: "template.code_explain.description",
            icon: "doc.plaintext",
            fields: [
                TemplateField(
                    id: "code",
                    labelKey: "template.code_explain.field.code.label",
                    placeholderKey: "template.code_explain.field.code.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "language",
                    labelKey: "template.code_explain.field.language.label",
                    placeholderKey: "template.code_explain.field.language.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.common.lang.swift",
                        "template.common.lang.python",
                        "template.common.lang.javascript",
                        "template.common.lang.typescript",
                        "template.common.lang.java",
                        "template.common.lang.go",
                        "template.common.lang.rust",
                        "template.common.lang.other"
                    ],
                    defaultValueKey: "template.common.lang.swift"
                ),
                TemplateField(
                    id: "detail_level",
                    labelKey: "template.code_explain.field.detail_level.label",
                    placeholderKey: "template.code_explain.field.detail_level.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.code_explain.field.detail_level.option.brief",
                        "template.code_explain.field.detail_level.option.line_by_line",
                        "template.code_explain.field.detail_level.option.deep"
                    ],
                    defaultValueKey: "template.code_explain.field.detail_level.option.line_by_line"
                )
            ],
            systemPromptKey: "template.code_explain.system_prompt",
            userPromptTemplateKey: "template.code_explain.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.code", "template.tag.explain", "template.tag.learning"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // Bug 修复
        SceneTemplate(
            id: "code_debug",
            nameKey: "template.code_debug.name",
            category: .programming,
            descriptionKey: "template.code_debug.description",
            icon: "ladybug",
            fields: [
                TemplateField(
                    id: "buggy_code",
                    labelKey: "template.code_debug.field.buggy_code.label",
                    placeholderKey: "template.code_debug.field.buggy_code.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "error_message",
                    labelKey: "template.code_debug.field.error_message.label",
                    placeholderKey: "template.code_debug.field.error_message.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "expected_behavior",
                    labelKey: "template.code_debug.field.expected_behavior.label",
                    placeholderKey: "template.code_debug.field.expected_behavior.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "language",
                    labelKey: "template.code_debug.field.language.label",
                    placeholderKey: "template.code_debug.field.language.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.common.lang.swift",
                        "template.common.lang.python",
                        "template.common.lang.javascript",
                        "template.common.lang.typescript",
                        "template.common.lang.java",
                        "template.common.lang.go",
                        "template.common.lang.rust",
                        "template.common.lang.other"
                    ],
                    defaultValueKey: "template.common.lang.swift"
                )
            ],
            systemPromptKey: "template.code_debug.system_prompt",
            userPromptTemplateKey: "template.code_debug.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.bug", "template.tag.debug", "template.tag.fix"],
            isPremium: false,
            usageCount: 0,
            order: 2
        ),

        // 代码优化
        SceneTemplate(
            id: "code_optimize",
            nameKey: "template.code_optimize.name",
            category: .programming,
            descriptionKey: "template.code_optimize.description",
            icon: "gauge.with.dots.needle.67percent",
            fields: [
                TemplateField(
                    id: "code",
                    labelKey: "template.code_optimize.field.code.label",
                    placeholderKey: "template.code_optimize.field.code.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "language",
                    labelKey: "template.code_optimize.field.language.label",
                    placeholderKey: "template.code_optimize.field.language.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.common.lang.swift",
                        "template.common.lang.python",
                        "template.common.lang.javascript",
                        "template.common.lang.typescript",
                        "template.common.lang.java",
                        "template.common.lang.go",
                        "template.common.lang.rust",
                        "template.common.lang.other"
                    ],
                    defaultValueKey: "template.common.lang.swift"
                ),
                TemplateField(
                    id: "focus",
                    labelKey: "template.code_optimize.field.focus.label",
                    placeholderKey: "template.code_optimize.field.focus.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.code_optimize.field.focus.option.performance",
                        "template.code_optimize.field.focus.option.readability",
                        "template.code_optimize.field.focus.option.security",
                        "template.code_optimize.field.focus.option.best_practices",
                        "template.code_optimize.field.focus.option.comprehensive"
                    ],
                    defaultValueKey: "template.code_optimize.field.focus.option.comprehensive"
                )
            ],
            systemPromptKey: "template.code_optimize.system_prompt",
            userPromptTemplateKey: "template.code_optimize.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.optimize", "template.tag.refactor", "template.tag.code_quality"],
            isPremium: true,
            usageCount: 0,
            order: 3
        )
    ]

    // MARK: - 营销文案模板
    static let marketingTemplates: [SceneTemplate] = [
        // 产品描述
        SceneTemplate(
            id: "marketing_product",
            nameKey: "template.marketing_product.name",
            category: .marketing,
            descriptionKey: "template.marketing_product.description",
            icon: "tag",
            fields: [
                TemplateField(
                    id: "product_name",
                    labelKey: "template.marketing_product.field.product_name.label",
                    placeholderKey: "template.marketing_product.field.product_name.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "product_category",
                    labelKey: "template.marketing_product.field.product_category.label",
                    placeholderKey: "template.marketing_product.field.product_category.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "key_features",
                    labelKey: "template.marketing_product.field.key_features.label",
                    placeholderKey: "template.marketing_product.field.key_features.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "target_audience",
                    labelKey: "template.marketing_product.field.target_audience.label",
                    placeholderKey: "template.marketing_product.field.target_audience.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "tone",
                    labelKey: "template.marketing_product.field.tone.label",
                    placeholderKey: "template.marketing_product.field.tone.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.marketing_product.field.tone.option.professional",
                        "template.marketing_product.field.tone.option.warm",
                        "template.marketing_product.field.tone.option.youthful",
                        "template.marketing_product.field.tone.option.luxury"
                    ],
                    defaultValueKey: "template.marketing_product.field.tone.option.warm"
                )
            ],
            systemPromptKey: "template.marketing_product.system_prompt",
            userPromptTemplateKey: "template.marketing_product.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.product", "template.tag.description", "template.tag.ecommerce"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // 广告语
        SceneTemplate(
            id: "marketing_slogan",
            nameKey: "template.marketing_slogan.name",
            category: .marketing,
            descriptionKey: "template.marketing_slogan.description",
            icon: "megaphone",
            fields: [
                TemplateField(
                    id: "brand_name",
                    labelKey: "template.marketing_slogan.field.brand_name.label",
                    placeholderKey: "template.marketing_slogan.field.brand_name.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "brand_positioning",
                    labelKey: "template.marketing_slogan.field.brand_positioning.label",
                    placeholderKey: "template.marketing_slogan.field.brand_positioning.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "keywords",
                    labelKey: "template.marketing_slogan.field.keywords.label",
                    placeholderKey: "template.marketing_slogan.field.keywords.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "style",
                    labelKey: "template.marketing_slogan.field.style.label",
                    placeholderKey: "template.marketing_slogan.field.style.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.marketing_slogan.field.style.option.concise",
                        "template.marketing_slogan.field.style.option.emotional",
                        "template.marketing_slogan.field.style.option.humorous",
                        "template.marketing_slogan.field.style.option.grand"
                    ],
                    defaultValueKey: "template.marketing_slogan.field.style.option.concise"
                )
            ],
            systemPromptKey: "template.marketing_slogan.system_prompt",
            userPromptTemplateKey: "template.marketing_slogan.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.slogan", "template.tag.brand", "template.tag.creative"],
            isPremium: true,
            usageCount: 0,
            order: 2
        )
    ]

    // MARK: - 教育学习模板
    static let educationTemplates: [SceneTemplate] = [
        SceneTemplate(
            id: "edu_explain",
            nameKey: "template.edu_explain.name",
            category: .education,
            descriptionKey: "template.edu_explain.description",
            icon: "lightbulb",
            fields: [
                TemplateField(
                    id: "concept",
                    labelKey: "template.edu_explain.field.concept.label",
                    placeholderKey: "template.edu_explain.field.concept.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "subject",
                    labelKey: "template.edu_explain.field.subject.label",
                    placeholderKey: "template.edu_explain.field.subject.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "audience_level",
                    labelKey: "template.edu_explain.field.audience_level.label",
                    placeholderKey: "template.edu_explain.field.audience_level.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.edu_explain.field.audience_level.option.elementary",
                        "template.edu_explain.field.audience_level.option.middle_school",
                        "template.edu_explain.field.audience_level.option.high_school",
                        "template.edu_explain.field.audience_level.option.college",
                        "template.edu_explain.field.audience_level.option.professional"
                    ],
                    defaultValueKey: "template.edu_explain.field.audience_level.option.high_school"
                )
            ],
            systemPromptKey: "template.edu_explain.system_prompt",
            userPromptTemplateKey: "template.edu_explain.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.learning", "template.tag.explain", "template.tag.education"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // 学习计划生成
        SceneTemplate(
            id: "edu_study_plan",
            nameKey: "template.edu_study_plan.name",
            category: .education,
            descriptionKey: "template.edu_study_plan.description",
            icon: "calendar.badge.clock",
            fields: [
                TemplateField(
                    id: "learning_goal",
                    labelKey: "template.edu_study_plan.field.learning_goal.label",
                    placeholderKey: "template.edu_study_plan.field.learning_goal.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "current_level",
                    labelKey: "template.edu_study_plan.field.current_level.label",
                    placeholderKey: "template.edu_study_plan.field.current_level.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "available_time",
                    labelKey: "template.edu_study_plan.field.available_time.label",
                    placeholderKey: "template.edu_study_plan.field.available_time.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "deadline",
                    labelKey: "template.edu_study_plan.field.deadline.label",
                    placeholderKey: "template.edu_study_plan.field.deadline.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.edu_study_plan.field.deadline.option.1month",
                        "template.edu_study_plan.field.deadline.option.3months",
                        "template.edu_study_plan.field.deadline.option.6months",
                        "template.edu_study_plan.field.deadline.option.1year"
                    ],
                    defaultValueKey: "template.edu_study_plan.field.deadline.option.3months"
                )
            ],
            systemPromptKey: "template.edu_study_plan.system_prompt",
            userPromptTemplateKey: "template.edu_study_plan.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.learning", "template.tag.plan", "template.tag.time_management"],
            isPremium: false,
            usageCount: 0,
            order: 2
        ),

        // 错题分析
        SceneTemplate(
            id: "edu_mistake_analysis",
            nameKey: "template.edu_mistake_analysis.name",
            category: .education,
            descriptionKey: "template.edu_mistake_analysis.description",
            icon: "xmark.circle",
            fields: [
                TemplateField(
                    id: "question",
                    labelKey: "template.edu_mistake_analysis.field.question.label",
                    placeholderKey: "template.edu_mistake_analysis.field.question.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "wrong_answer",
                    labelKey: "template.edu_mistake_analysis.field.wrong_answer.label",
                    placeholderKey: "template.edu_mistake_analysis.field.wrong_answer.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "correct_answer",
                    labelKey: "template.edu_mistake_analysis.field.correct_answer.label",
                    placeholderKey: "template.edu_mistake_analysis.field.correct_answer.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "subject",
                    labelKey: "template.edu_mistake_analysis.field.subject.label",
                    placeholderKey: "template.edu_mistake_analysis.field.subject.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.edu_mistake_analysis.field.subject.option.math",
                        "template.edu_mistake_analysis.field.subject.option.physics",
                        "template.edu_mistake_analysis.field.subject.option.chemistry",
                        "template.edu_mistake_analysis.field.subject.option.english",
                        "template.edu_mistake_analysis.field.subject.option.chinese",
                        "template.edu_mistake_analysis.field.subject.option.other"
                    ],
                    defaultValueKey: "template.edu_mistake_analysis.field.subject.option.math"
                )
            ],
            systemPromptKey: "template.edu_mistake_analysis.system_prompt",
            userPromptTemplateKey: "template.edu_mistake_analysis.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.mistake", "template.tag.analysis", "template.tag.review"],
            isPremium: true,
            usageCount: 0,
            order: 3
        )
    ]

    // MARK: - 创意写作模板
    static let creativeTemplates: [SceneTemplate] = [
        SceneTemplate(
            id: "creative_story",
            nameKey: "template.creative_story.name",
            category: .creative,
            descriptionKey: "template.creative_story.description",
            icon: "book",
            fields: [
                TemplateField(
                    id: "theme",
                    labelKey: "template.creative_story.field.theme.label",
                    placeholderKey: "template.creative_story.field.theme.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "setting",
                    labelKey: "template.creative_story.field.setting.label",
                    placeholderKey: "template.creative_story.field.setting.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "characters",
                    labelKey: "template.creative_story.field.characters.label",
                    placeholderKey: "template.creative_story.field.characters.placeholder",
                    fieldType: .textarea,
                    isRequired: false
                ),
                TemplateField(
                    id: "length",
                    labelKey: "template.creative_story.field.length.label",
                    placeholderKey: "template.creative_story.field.length.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.creative_story.field.length.option.micro",
                        "template.creative_story.field.length.option.short",
                        "template.creative_story.field.length.option.medium"
                    ],
                    defaultValueKey: "template.creative_story.field.length.option.short"
                )
            ],
            systemPromptKey: "template.creative_story.system_prompt",
            userPromptTemplateKey: "template.creative_story.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.story", "template.tag.creative", "template.tag.writing"],
            isPremium: false,
            usageCount: 0,
            order: 1
        ),

        // 诗歌创作
        SceneTemplate(
            id: "creative_poem",
            nameKey: "template.creative_poem.name",
            category: .creative,
            descriptionKey: "template.creative_poem.description",
            icon: "text.quote",
            fields: [
                TemplateField(
                    id: "theme",
                    labelKey: "template.creative_poem.field.theme.label",
                    placeholderKey: "template.creative_poem.field.theme.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "style",
                    labelKey: "template.creative_poem.field.style.label",
                    placeholderKey: "template.creative_poem.field.style.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.creative_poem.field.style.option.modern",
                        "template.creative_poem.field.style.option.classical",
                        "template.creative_poem.field.style.option.haiku",
                        "template.creative_poem.field.style.option.limerick",
                        "template.creative_poem.field.style.option.prose"
                    ],
                    defaultValueKey: "template.creative_poem.field.style.option.modern"
                ),
                TemplateField(
                    id: "mood",
                    labelKey: "template.creative_poem.field.mood.label",
                    placeholderKey: "template.creative_poem.field.mood.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.creative_poem.field.mood.option.joyful",
                        "template.creative_poem.field.mood.option.melancholic",
                        "template.creative_poem.field.mood.option.heroic",
                        "template.creative_poem.field.mood.option.serene",
                        "template.creative_poem.field.mood.option.profound"
                    ],
                    defaultValueKey: "template.creative_poem.field.mood.option.serene"
                ),
                TemplateField(
                    id: "keywords",
                    labelKey: "template.creative_poem.field.keywords.label",
                    placeholderKey: "template.creative_poem.field.keywords.placeholder",
                    fieldType: .text,
                    isRequired: false
                )
            ],
            systemPromptKey: "template.creative_poem.system_prompt",
            userPromptTemplateKey: "template.creative_poem.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.poem", "template.tag.creative", "template.tag.literature"],
            isPremium: false,
            usageCount: 0,
            order: 2
        ),

        // 文案改写
        SceneTemplate(
            id: "creative_rewrite",
            nameKey: "template.creative_rewrite.name",
            category: .creative,
            descriptionKey: "template.creative_rewrite.description",
            icon: "arrow.triangle.2.circlepath",
            fields: [
                TemplateField(
                    id: "original_text",
                    labelKey: "template.creative_rewrite.field.original_text.label",
                    placeholderKey: "template.creative_rewrite.field.original_text.placeholder",
                    fieldType: .textarea,
                    isRequired: true
                ),
                TemplateField(
                    id: "target_style",
                    labelKey: "template.creative_rewrite.field.target_style.label",
                    placeholderKey: "template.creative_rewrite.field.target_style.placeholder",
                    fieldType: .select,
                    isRequired: true,
                    optionKeys: [
                        "template.creative_rewrite.field.target_style.option.literary",
                        "template.creative_rewrite.field.target_style.option.humorous",
                        "template.creative_rewrite.field.target_style.option.formal",
                        "template.creative_rewrite.field.target_style.option.internet",
                        "template.creative_rewrite.field.target_style.option.classical",
                        "template.creative_rewrite.field.target_style.option.simple"
                    ],
                    defaultValueKey: "template.creative_rewrite.field.target_style.option.literary"
                ),
                TemplateField(
                    id: "keep_meaning",
                    labelKey: "template.creative_rewrite.field.keep_meaning.label",
                    placeholderKey: "template.creative_rewrite.field.keep_meaning.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.creative_rewrite.field.keep_meaning.option.full",
                        "template.creative_rewrite.field.keep_meaning.option.core",
                        "template.creative_rewrite.field.keep_meaning.option.free"
                    ],
                    defaultValueKey: "template.creative_rewrite.field.keep_meaning.option.core"
                )
            ],
            systemPromptKey: "template.creative_rewrite.system_prompt",
            userPromptTemplateKey: "template.creative_rewrite.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.rewrite", "template.tag.style", "template.tag.copywriting"],
            isPremium: true,
            usageCount: 0,
            order: 3
        ),

        // 朋友圈文案
        SceneTemplate(
            id: "creative_moments",
            nameKey: "template.creative_moments.name",
            category: .creative,
            descriptionKey: "template.creative_moments.description",
            icon: "bubble.left.and.text.bubble.right",
            fields: [
                TemplateField(
                    id: "scene",
                    labelKey: "template.creative_moments.field.scene.label",
                    placeholderKey: "template.creative_moments.field.scene.placeholder",
                    fieldType: .text,
                    isRequired: true
                ),
                TemplateField(
                    id: "mood",
                    labelKey: "template.creative_moments.field.mood.label",
                    placeholderKey: "template.creative_moments.field.mood.placeholder",
                    fieldType: .text,
                    isRequired: false
                ),
                TemplateField(
                    id: "style",
                    labelKey: "template.creative_moments.field.style.label",
                    placeholderKey: "template.creative_moments.field.style.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.creative_moments.field.style.option.literary",
                        "template.creative_moments.field.style.option.humorous",
                        "template.creative_moments.field.style.option.minimal",
                        "template.creative_moments.field.style.option.inspirational",
                        "template.creative_moments.field.style.option.sentimental"
                    ],
                    defaultValueKey: "template.creative_moments.field.style.option.literary"
                ),
                TemplateField(
                    id: "length",
                    labelKey: "template.creative_moments.field.length.label",
                    placeholderKey: "template.creative_moments.field.length.placeholder",
                    fieldType: .select,
                    isRequired: false,
                    optionKeys: [
                        "template.creative_moments.field.length.option.one_line",
                        "template.creative_moments.field.length.option.short",
                        "template.creative_moments.field.length.option.paragraph"
                    ],
                    defaultValueKey: "template.creative_moments.field.length.option.short"
                )
            ],
            systemPromptKey: "template.creative_moments.system_prompt",
            userPromptTemplateKey: "template.creative_moments.user_prompt",
            exampleOutputKey: nil,
            tagKeys: ["template.tag.moments", "template.tag.social", "template.tag.copywriting"],
            isPremium: false,
            usageCount: 0,
            order: 4
        )
    ]
}
