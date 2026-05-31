import SwiftUI
import Speech
import AVFoundation
import Security
import UniformTypeIdentifiers
import PDFKit
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct Message: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    var feedback: UserSentenceFeedback?

    init(
        id: UUID = UUID(),
        text: String,
        isUser: Bool,
        feedback: UserSentenceFeedback? = nil
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.feedback = feedback
    }
}

struct UserSentenceFeedback: Equatable {
    enum Level: String {
        case good = "OK"
        case warning = "WARN"
        case bad = "BAD"
    }

    let level: Level
    let correction: String
    let alternative: String?

    var iconSystemName: String {
        switch level {
        case .good: return "checkmark"
        case .warning: return "exclamationmark"
        case .bad: return "xmark"
        }
    }

    var iconBackgroundColor: Color {
        switch level {
        case .good:
            return Color(red: 0.14, green: 0.67, blue: 0.35)
        case .warning:
            return Color(red: 0.95, green: 0.75, blue: 0.20)
        case .bad:
            return Color(red: 0.85, green: 0.24, blue: 0.24)
        }
    }

    var iconForegroundColor: Color {
        switch level {
        case .good, .bad:
            return .white
        case .warning:
            return Color(red: 0.18, green: 0.16, blue: 0.08)
        }
    }

}

enum ConversationMode: String, CaseIterable, Identifiable {
    case russian = "Russisch"
    case turkish = "Türkisch"
    case english = "Englisch"
    case ukrainian = "Ukrainisch"
    case italian = "Italienisch"
    case spanish = "Spanisch"
    case german = "Deutsch"

    var id: String { rawValue }

    static func fromStoredValue(_ raw: String) -> ConversationMode {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = ConversationMode(rawValue: cleaned) {
            return direct
        }
        switch cleaned.lowercased() {
        case "russian", "русский":
            return .russian
        case "turkish", "türkisch", "tuerkisch", "türkçe", "turkce":
            return .turkish
        case "english", "englisch", "ingilizce":
            return .english
        case "ukrainian", "українська":
            return .ukrainian
        case "italian", "italienisch", "italiano":
            return .italian
        case "spanish", "spanisch", "español", "espanol":
            return .spanish
        case "german", "deutsch", "de":
            return .german
        default:
            return .russian
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .russian:
            return "ru-RU"
        case .turkish:
            return "tr-TR"
        case .english:
            return "en-US"
        case .ukrainian:
            return "uk-UA"
        case .italian:
            return "it-IT"
        case .spanish:
            return "es-ES"
        case .german:
            return "de-DE"
        }
    }

    var speechLanguagePrefix: String {
        switch self {
        case .russian:
            return "ru"
        case .turkish:
            return "tr"
        case .english:
            return "en"
        case .ukrainian:
            return "uk"
        case .italian:
            return "it"
        case .spanish:
            return "es"
        case .german:
            return "de"
        }
    }

    func displayName(for language: AppLanguage) -> String {
        if language == .spanish {
            switch self {
            case .russian: return "Ruso"
            case .turkish: return "Turco"
            case .english: return "Inglés"
            case .ukrainian: return "Ucraniano"
            case .italian: return "Italiano"
            case .spanish: return "Español"
            case .german: return "Alemán"
            }
        }
        if language == .russian {
            switch self {
            case .russian: return "Русский"
            case .turkish: return "Турецкий"
            case .english: return "Английский"
            case .ukrainian: return "Украинский"
            case .italian: return "Итальянский"
            case .spanish: return "Испанский"
            case .german: return "Немецкий"
            }
        }
        if language == .ukrainian {
            switch self {
            case .russian: return "Російська"
            case .turkish: return "Турецька"
            case .english: return "Англійська"
            case .ukrainian: return "Українська"
            case .italian: return "Італійська"
            case .spanish: return "Іспанська"
            case .german: return "Німецька"
            }
        }
        switch (self, language.localizationFamily) {
        case (.russian, .german): return "Russisch"
        case (.turkish, .german): return "Türkisch"
        case (.english, .german): return "Englisch"
        case (.ukrainian, .german): return "Ukrainisch"
        case (.italian, .german): return "Italienisch"
        case (.spanish, .german): return "Spanisch"
        case (.german, .german): return "Deutsch"

        case (.russian, .turkish): return "Rusça"
        case (.turkish, .turkish): return "Türkçe"
        case (.english, .turkish): return "İngilizce"
        case (.ukrainian, .turkish): return "Ukraynaca"
        case (.italian, .turkish): return "İtalyanca"
        case (.spanish, .turkish): return "İspanyolca"
        case (.german, .turkish): return "Almanca"

        case (.russian, .english): return "Russian"
        case (.turkish, .english): return "Turkish"
        case (.english, .english): return "English"
        case (.ukrainian, .english): return "Ukrainian"
        case (.italian, .english): return "Italian"
        case (.spanish, .english): return "Spanish"
        case (.german, .english): return "German"
        }
    }
}

enum ConversationTopic: String, CaseIterable, Identifiable {
    case automatic = "automatic"
    case dailyLife = "daily_life"
    case cooking = "cooking"
    case work = "work"
    case general = "general"
    case travel = "travel"
    case hobbies = "hobbies"
    case family = "family"
    case shopping = "shopping"
    case gaming = "gaming"
    case politics = "politics"
    case socialMedia = "social_media"

    var id: String { rawValue }

    func displayName(for language: AppLanguage) -> String {
        if language == .spanish {
            switch self {
            case .automatic: return "Automático"
            case .dailyLife: return "Vida diaria"
            case .cooking: return "Cocina"
            case .work: return "Trabajo"
            case .general: return "General"
            case .travel: return "Viajes"
            case .hobbies: return "Pasatiempos"
            case .family: return "Familia"
            case .shopping: return "Compras"
            case .gaming: return "Videojuegos"
            case .politics: return "Política"
            case .socialMedia: return "Redes sociales"
            }
        }
        if language == .russian {
            switch self {
            case .automatic: return "Авто"
            case .dailyLife: return "Повседневная жизнь"
            case .cooking: return "Кулинария"
            case .work: return "Работа"
            case .general: return "Общее"
            case .travel: return "Путешествия"
            case .hobbies: return "Хобби"
            case .family: return "Семья"
            case .shopping: return "Покупки"
            case .gaming: return "Видеоигры"
            case .politics: return "Политика"
            case .socialMedia: return "Соцсети"
            }
        }
        if language == .ukrainian {
            switch self {
            case .automatic: return "Автоматично"
            case .dailyLife: return "Повсякденне життя"
            case .cooking: return "Кулінарія"
            case .work: return "Робота"
            case .general: return "Загальне"
            case .travel: return "Подорожі"
            case .hobbies: return "Хобі"
            case .family: return "Сім'я"
            case .shopping: return "Покупки"
            case .gaming: return "Відеоігри"
            case .politics: return "Політика"
            case .socialMedia: return "Соцмережі"
            }
        }
        switch (self, language.localizationFamily) {
        case (.automatic, .german): return "Automatisch"
        case (.dailyLife, .german): return "Alltag"
        case (.cooking, .german): return "Kochen"
        case (.work, .german): return "Arbeit"
        case (.general, .german): return "Allgemein"
        case (.travel, .german): return "Reisen"
        case (.hobbies, .german): return "Hobbys"
        case (.family, .german): return "Familie"
        case (.shopping, .german): return "Einkaufen"
        case (.gaming, .german): return "Computerspiele"
        case (.politics, .german): return "Politik"
        case (.socialMedia, .german): return "Soziale Medien"

        case (.automatic, .turkish): return "Otomatik"
        case (.dailyLife, .turkish): return "Günlük Yaşam"
        case (.cooking, .turkish): return "Yemek"
        case (.work, .turkish): return "İş"
        case (.general, .turkish): return "Genel"
        case (.travel, .turkish): return "Seyahat"
        case (.hobbies, .turkish): return "Hobiler"
        case (.family, .turkish): return "Aile"
        case (.shopping, .turkish): return "Alışveriş"
        case (.gaming, .turkish): return "Bilgisayar Oyunları"
        case (.politics, .turkish): return "Siyaset"
        case (.socialMedia, .turkish): return "Sosyal Medya"

        case (.automatic, .english): return "Automatic"
        case (.dailyLife, .english): return "Daily Life"
        case (.cooking, .english): return "Cooking"
        case (.work, .english): return "Work"
        case (.general, .english): return "General"
        case (.travel, .english): return "Travel"
        case (.hobbies, .english): return "Hobbies"
        case (.family, .english): return "Family"
        case (.shopping, .english): return "Shopping"
        case (.gaming, .english): return "Video Games"
        case (.politics, .english): return "Politics"
        case (.socialMedia, .english): return "Social Media"
        }
    }

    var promptLabel: String {
        switch self {
        case .automatic: return "Automatisch"
        case .dailyLife: return "Alltag"
        case .cooking: return "Kochen"
        case .work: return "Arbeit"
        case .general: return "Allgemein"
        case .travel: return "Reisen"
        case .hobbies: return "Hobbys"
        case .family: return "Familie"
        case .shopping: return "Einkaufen"
        case .gaming: return "Computerspiele"
        case .politics: return "Politik"
        case .socialMedia: return "Soziale Medien"
        }
    }

    static func fromStoredValue(_ raw: String) -> ConversationTopic {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = ConversationTopic(rawValue: cleaned) {
            return direct
        }

        switch cleaned.lowercased() {
        case "automatisch", "automatic", "otomatik":
            return .automatic
        case "alltag", "daily life", "günlük yaşam", "gunluk yasam":
            return .dailyLife
        case "kochen", "cooking", "yemek":
            return .cooking
        case "arbeit", "work", "iş", "is":
            return .work
        case "allgemein", "general", "genel":
            return .general
        case "reisen", "travel", "seyahat":
            return .travel
        case "hobbys", "hobbies", "hobiler":
            return .hobbies
        case "familie", "family", "aile":
            return .family
        case "einkaufen", "shopping", "alışveriş", "alisveris":
            return .shopping
        case "computerspiele", "video games", "bilgisayar oyunları", "bilgisayar oyunlari":
            return .gaming
        case "politik", "politics", "siyaset":
            return .politics
        case "soziale medien", "social media", "sosyal medya":
            return .socialMedia
        default:
            return .automatic
        }
    }
}

enum MaterialLearningMode {
    case vocabulary
    case sentences
    case sectionVocabulary
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "Deutsch"
    case turkish = "Türkçe"
    case english = "English"
    case ukrainian = "Українська"
    case spanish = "Español"
    case russian = "Русский"

    var id: String { rawValue }

    static func fromStoredValue(_ raw: String) -> AppLanguage {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = AppLanguage(rawValue: cleaned) {
            return direct
        }

        switch cleaned.lowercased() {
        case "deutsch", "german", "de":
            return .german
        case "türkisch", "tuerkisch", "türkçe", "turkce", "turkish", "tr":
            return .turkish
        case "englisch", "english", "en":
            return .english
        case "українська", "ukrainian", "uk":
            return .ukrainian
        case "español", "espanol", "spanish", "es":
            return .spanish
        case "русский", "russian", "ru":
            return .russian
        default:
            return .german
        }
    }

    enum LocalizationFamily {
        case german
        case turkish
        case english
    }

    var localizationFamily: LocalizationFamily {
        switch self {
        case .german:
            return .german
        case .turkish:
            return .turkish
        case .english, .ukrainian, .spanish, .russian:
            return .english
        }
    }

    var flag: String {
        switch self {
        case .german:
            return "🇩🇪"
        case .turkish:
            return "🇹🇷"
        case .english:
            return "🇬🇧"
        case .ukrainian:
            return "🇺🇦"
        case .spanish:
            return "🇪🇸"
        case .russian:
            return "🇷🇺"
        }
    }

    var inputPlaceholder: String {
        if self == .ukrainian {
            return "Пишіть тут..."
        }
        if self == .spanish {
            return "Escribe aquí..."
        }
        if self == .russian {
            return "Введите здесь..."
        }
        switch localizationFamily {
        case .german:
            return "Schreibe hier..."
        case .turkish:
            return "Buraya yazınız..."
        case .english:
            return "Type here..."
        }
    }

    var correctionAccessibilityLabel: String {
        if self == .ukrainian {
            return "Показати виправлення"
        }
        if self == .spanish {
            return "Mostrar corrección"
        }
        if self == .russian {
            return "Показать исправление"
        }
        switch localizationFamily {
        case .german:
            return "Korrektur anzeigen"
        case .turkish:
            return "Düzeltmeyi göster"
        case .english:
            return "Show correction"
        }
    }

    var replayLabel: String {
        if self == .ukrainian {
            return "Повтор"
        }
        if self == .spanish {
            return "Repetir"
        }
        if self == .russian {
            return "Повтор"
        }
        switch localizationFamily {
        case .german:
            return "Nochmal"
        case .turkish:
            return "Tekrar"
        case .english:
            return "Replay"
        }
    }

    var replayFromStartLabel: String {
        if self == .ukrainian {
            return "З початку"
        }
        if self == .spanish {
            return "Reiniciar"
        }
        if self == .russian {
            return "Сначала"
        }
        switch localizationFamily {
        case .german:
            return "Neu starten"
        case .turkish:
            return "Baştan oynat"
        case .english:
            return "Replay from start"
        }
    }

    var pauseLabel: String {
        if self == .ukrainian {
            return "Пауза"
        }
        if self == .spanish {
            return "Pausa"
        }
        if self == .russian {
            return "Пауза"
        }
        switch localizationFamily {
        case .german:
            return "Pause"
        case .turkish:
            return "Duraklat"
        case .english:
            return "Pause"
        }
    }

    var resumeLabel: String {
        if self == .ukrainian {
            return "Продовжити"
        }
        if self == .spanish {
            return "Continuar"
        }
        if self == .russian {
            return "Продолжить"
        }
        switch localizationFamily {
        case .german:
            return "Fortsetzen"
        case .turkish:
            return "Devam et"
        case .english:
            return "Resume"
        }
    }

    var listenLabel: String {
        if self == .ukrainian {
            return "Слухати"
        }
        if self == .spanish {
            return "Escuchar"
        }
        if self == .russian {
            return "Слушать"
        }
        switch localizationFamily {
        case .german:
            return "Anhören"
        case .turkish:
            return "Dinle"
        case .english:
            return "Listen"
        }
    }

    var alternativeLabel: String {
        if self == .ukrainian {
            return "Альтернатива"
        }
        if self == .spanish {
            return "Alternativa"
        }
        if self == .russian {
            return "Вариант"
        }
        switch localizationFamily {
        case .german:
            return "Alternative"
        case .turkish:
            return "Alternatif"
        case .english:
            return "Alternative"
        }
    }

    var alternativePrefix: String {
        if self == .ukrainian {
            return "Альтернатива:"
        }
        if self == .spanish {
            return "Alternativa:"
        }
        if self == .russian {
            return "Вариант:"
        }
        switch localizationFamily {
        case .german:
            return "Alternative:"
        case .turkish:
            return "Alternatif:"
        case .english:
            return "Alternative:"
        }
    }

    var closeLabel: String {
        if self == .spanish {
            return "Cerrar"
        }
        if self == .russian {
            return "Закрыть"
        }
        if self == .ukrainian {
            return "Закрити"
        }
        switch localizationFamily {
        case .german:
            return "Schließen"
        case .turkish:
            return "Kapat"
        case .english:
            return "Close"
        }
    }

    var speedLabelWord: String {
        if self == .ukrainian {
            return "Швидкість"
        }
        if self == .spanish {
            return "Velocidad"
        }
        if self == .russian {
            return "Скорость"
        }
        switch localizationFamily {
        case .german:
            return "Tempo"
        case .turkish:
            return "Hız"
        case .english:
            return "Speed"
        }
    }

    var settingsHintText: String {
        if self == .spanish {
            return "Controla el texto del campo y las pistas de corrección en los globos."
        }
        if self == .russian {
            return "Управляет подсказкой ввода и подсказками исправления в пузырях."
        }
        if self == .ukrainian {
            return "Керує плейсхолдером і підказками виправлення в бульбашках."
        }
        switch localizationFamily {
        case .german:
            return "Steuert Platzhalter und Korrekturhinweise in den Sprechblasen."
        case .turkish:
            return "Konuşma balonlarındaki yer tutucu ve düzeltme ipuçlarını belirler."
        case .english:
            return "Controls placeholder and correction hints in speech bubbles."
        }
    }

    var appLanguagePickerAccessibilityLabel: String {
        if self == .spanish {
            return "Elegir idioma de la app"
        }
        if self == .russian {
            return "Выбрать язык приложения"
        }
        if self == .ukrainian {
            return "Виберіть мову застосунку"
        }
        switch localizationFamily {
        case .german:
            return "Appsprache waehlen"
        case .turkish:
            return "Uygulama dilini seç"
        case .english:
            return "Choose app language"
        }
    }

    var learningLanguagePickerAccessibilityLabel: String {
        if self == .spanish {
            return "Elegir idioma de aprendizaje"
        }
        if self == .russian {
            return "Выбрать язык обучения"
        }
        if self == .ukrainian {
            return "Вибрати мову навчання"
        }
        switch localizationFamily {
        case .german:
            return "Lernsprache waehlen"
        case .turkish:
            return "Ogrenme dilini sec"
        case .english:
            return "Choose learning language"
        }
    }

    var levelPickerAccessibilityLabel: String {
        if self == .spanish {
            return "Elegir nivel de idioma"
        }
        if self == .russian {
            return "Выбрать языковой уровень"
        }
        if self == .ukrainian {
            return "Вибрати мовний рівень"
        }
        switch localizationFamily {
        case .german:
            return "Sprachniveau waehlen"
        case .turkish:
            return "Dil seviyesini sec"
        case .english:
            return "Choose language level"
        }
    }

    var bubbleActionTitle: String {
        if self == .spanish {
            return "Burbuja"
        }
        if self == .russian {
            return "Пузырь"
        }
        if self == .ukrainian {
            return "Бульбашка"
        }
        switch localizationFamily {
        case .german:
            return "Sprechblase"
        case .turkish:
            return "Konuşma balonu"
        case .english:
            return "Speech bubble"
        }
    }

    var translateActionLabel: String {
        if self == .spanish {
            return "Traducir"
        }
        if self == .russian {
            return "Перевести"
        }
        if self == .ukrainian {
            return "Перекласти"
        }
        switch localizationFamily {
        case .german:
            return "Uebersetzen"
        case .turkish:
            return "Çevir"
        case .english:
            return "Translate"
        }
    }

    var translationResultPrefix: String {
        if self == .spanish {
            return "Traducción:"
        }
        if self == .russian {
            return "Перевод:"
        }
        if self == .ukrainian {
            return "Переклад:"
        }
        switch localizationFamily {
        case .german:
            return "Uebersetzung:"
        case .turkish:
            return "Çeviri:"
        case .english:
            return "Translation:"
        }
    }

    var translationErrorPrefix: String {
        if self == .spanish {
            return "Error de traducción:"
        }
        if self == .russian {
            return "Ошибка перевода:"
        }
        if self == .ukrainian {
            return "Помилка перекладу:"
        }
        switch localizationFamily {
        case .german:
            return "Fehler bei Uebersetzung:"
        case .turkish:
            return "Çeviri hatası:"
        case .english:
            return "Translation error:"
        }
    }

    var translationTargetLanguageName: String {
        switch self {
        case .german:
            return "Deutsch"
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        case .ukrainian:
            return "Українська"
        case .spanish:
            return "Español"
        case .russian:
            return "Русский"
        }
    }

    var topicPickerTitle: String {
        if self == .spanish {
            return "Tema"
        }
        if self == .russian {
            return "Тема"
        }
        if self == .ukrainian {
            return "Тема"
        }
        switch localizationFamily {
        case .german:
            return "Rubrik"
        case .turkish:
            return "Konu"
        case .english:
            return "Topic"
        }
    }

    var sendLabel: String {
        if self == .ukrainian {
            return "Надіслати"
        }
        if self == .spanish {
            return "Enviar"
        }
        if self == .russian {
            return "Отправить"
        }
        switch localizationFamily {
        case .german:
            return "Senden"
        case .turkish:
            return "Gönder"
        case .english:
            return "Send"
        }
    }

    var listeningNowLabel: String {
        if self == .ukrainian {
            return "Я слухаю..."
        }
        if self == .spanish {
            return "Estoy escuchando..."
        }
        if self == .russian {
            return "Слушаю..."
        }
        switch localizationFamily {
        case .german:
            return "Ich höre zu..."
        case .turkish:
            return "Seni dinliyorum..."
        case .english:
            return "I'm listening..."
        }
    }

    var holdToSpeakLabel: String {
        if self == .ukrainian {
            return "Утримуйте, щоб говорити"
        }
        if self == .spanish {
            return "Mantén pulsado para hablar"
        }
        if self == .russian {
            return "Удерживайте для речи"
        }
        switch localizationFamily {
        case .german:
            return "Halten zum Sprechen"
        case .turkish:
            return "Konuşmak için basılı tut"
        case .english:
            return "Hold to speak"
        }
    }

    var speechInputLabel: String {
        if self == .ukrainian {
            return "Голосове введення"
        }
        if self == .spanish {
            return "Entrada de voz"
        }
        if self == .russian {
            return "Голосовой ввод"
        }
        switch localizationFamily {
        case .german:
            return "Spracheingabe"
        case .turkish:
            return "Ses girişi"
        case .english:
            return "Speech input"
        }
    }

    var processingLabel: String {
        if self == .ukrainian {
            return "Обробка"
        }
        if self == .spanish {
            return "Procesando"
        }
        if self == .russian {
            return "Обработка"
        }
        switch localizationFamily {
        case .german:
            return "Verarbeite"
        case .turkish:
            return "İşleniyor"
        case .english:
            return "Processing"
        }
    }

    var enterSendHintLabel: String {
        if self == .ukrainian {
            return "Порада: натисніть Enter або Надіслати."
        }
        if self == .spanish {
            return "Consejo: pulsa Enter o Enviar."
        }
        if self == .russian {
            return "Подсказка: нажмите Enter или Отправить."
        }
        switch localizationFamily {
        case .german:
            return "Tipp: Enter oder Senden zum Abschicken."
        case .turkish:
            return "İpucu: Göndermek için Enter veya Gönder."
        case .english:
            return "Tip: Press Enter or Send to submit."
        }
    }

    var geminiKeyMissingLabel: String {
        if self == .ukrainian {
            return "Відсутній ключ Gemini."
        }
        if self == .spanish {
            return "Falta la clave de Gemini."
        }
        if self == .russian {
            return "Ключ Gemini отсутствует."
        }
        switch localizationFamily {
        case .german:
            return "Gemini-Key fehlt."
        case .turkish:
            return "Gemini anahtarı eksik."
        case .english:
            return "Gemini key is missing."
        }
    }

    var groqKeyMissingLabel: String {
        if self == .ukrainian {
            return "Відсутній ключ Groq."
        }
        if self == .spanish {
            return "Falta la clave de Groq."
        }
        if self == .russian {
            return "Ключ Groq отсутствует."
        }
        switch localizationFamily {
        case .german:
            return "Groq-Key fehlt."
        case .turkish:
            return "Groq anahtarı eksik."
        case .english:
            return "Groq key is missing."
        }
    }

    var speechNotDetectedLabel: String {
        if self == .ukrainian {
            return "Мову не розпізнано. Утримуйте кнопку мікрофона під час мовлення й перевірте доступ до мікрофона."
        }
        if self == .spanish {
            return "No se detectó voz. Mantén pulsado el botón del micrófono al hablar y revisa el permiso del micrófono."
        }
        if self == .russian {
            return "Речь не распознана. Удерживайте кнопку микрофона во время речи и проверьте доступ к микрофону."
        }
        switch localizationFamily {
        case .german:
            return "Keine Sprache erkannt. Halte den Mikro-Button beim Sprechen gedrueckt und pruefe die Mikrofonfreigabe."
        case .turkish:
            return "Konuşma algılanmadı. Konuşurken mikrofon düğmesini basılı tut ve mikrofon iznini kontrol et."
        case .english:
            return "No speech detected. Hold the microphone button while speaking and check microphone permission."
        }
    }

    var settingsTitle: String {
        if self == .spanish {
            return "Ajustes"
        }
        if self == .russian {
            return "Настройки"
        }
        if self == .ukrainian {
            return "Налаштування"
        }
        switch localizationFamily {
        case .german:
            return "Einstellungen"
        case .turkish:
            return "Ayarlar"
        case .english:
            return "Settings"
        }
    }

    var modelSectionTitle: String {
        if self == .spanish {
            return "Modelo"
        }
        if self == .russian {
            return "Модель"
        }
        if self == .ukrainian {
            return "Модель"
        }
        switch localizationFamily {
        case .german:
            return "Modell"
        case .turkish:
            return "Model"
        case .english:
            return "Model"
        }
    }

    var providerPickerTitle: String {
        if self == .spanish {
            return "Proveedor"
        }
        if self == .russian {
            return "Провайдер"
        }
        if self == .ukrainian {
            return "Провайдер"
        }
        switch localizationFamily {
        case .german:
            return "Provider"
        case .turkish:
            return "Sağlayıcı"
        case .english:
            return "Provider"
        }
    }

    var groqApiKeyFieldTitle: String {
        if self == .spanish {
            return "Clave API de Groq"
        }
        if self == .russian {
            return "Ключ API Groq"
        }
        if self == .ukrainian {
            return "Ключ Groq API"
        }
        switch localizationFamily {
        case .german:
            return "Groq API-Key"
        case .turkish:
            return "Groq API anahtarı"
        case .english:
            return "Groq API key"
        }
    }

    var geminiApiKeyFieldTitle: String {
        if self == .spanish {
            return "Clave API de Gemini"
        }
        if self == .russian {
            return "Ключ API Gemini"
        }
        if self == .ukrainian {
            return "Ключ Gemini API"
        }
        switch localizationFamily {
        case .german:
            return "Gemini API-Key"
        case .turkish:
            return "Gemini API anahtarı"
        case .english:
            return "Gemini API key"
        }
    }

    var groqSuggestionPickerTitle: String {
        if self == .spanish {
            return "Sugerencia de Groq"
        }
        if self == .russian {
            return "Рекомендация Groq"
        }
        if self == .ukrainian {
            return "Рекомендація Groq"
        }
        switch localizationFamily {
        case .german:
            return "Groq Vorschlag"
        case .turkish:
            return "Groq önerisi"
        case .english:
            return "Groq suggestion"
        }
    }

    var ollamaSuggestionPickerTitle: String {
        if self == .spanish {
            return "Sugerencia de Ollama"
        }
        if self == .russian {
            return "Рекомендация Ollama"
        }
        if self == .ukrainian {
            return "Рекомендація Ollama"
        }
        switch localizationFamily {
        case .german:
            return "Ollama Vorschlag"
        case .turkish:
            return "Ollama önerisi"
        case .english:
            return "Ollama suggestion"
        }
    }

    var geminiModelPickerTitle: String {
        if self == .spanish {
            return "Modelo de Gemini"
        }
        if self == .russian {
            return "Модель Gemini"
        }
        if self == .ukrainian {
            return "Модель Gemini"
        }
        switch localizationFamily {
        case .german:
            return "Gemini Modell"
        case .turkish:
            return "Gemini modeli"
        case .english:
            return "Gemini model"
        }
    }

    var automaticLabel: String {
        if self == .spanish {
            return "Automático"
        }
        if self == .russian {
            return "Авто"
        }
        if self == .ukrainian {
            return "Автоматично"
        }
        switch localizationFamily {
        case .german:
            return "Automatisch"
        case .turkish:
            return "Otomatik"
        case .english:
            return "Automatic"
        }
    }

    var customPrefix: String {
        if self == .spanish {
            return "Personalizado:"
        }
        if self == .russian {
            return "Своя модель:"
        }
        if self == .ukrainian {
            return "Власне:"
        }
        switch localizationFamily {
        case .german:
            return "Eigenes:"
        case .turkish:
            return "Özel:"
        case .english:
            return "Custom:"
        }
    }

    var currentPrefix: String {
        if self == .spanish {
            return "Actual:"
        }
        if self == .russian {
            return "Текущая:"
        }
        if self == .ukrainian {
            return "Поточне:"
        }
        switch localizationFamily {
        case .german:
            return "Aktuell:"
        case .turkish:
            return "Geçerli:"
        case .english:
            return "Current:"
        }
    }

    var groqCustomModelFieldTitle: String {
        if self == .spanish {
            return "Modelo de Groq (personalizado)"
        }
        if self == .russian {
            return "Модель Groq (своя)"
        }
        if self == .ukrainian {
            return "Модель Groq (власна)"
        }
        switch localizationFamily {
        case .german:
            return "Groq Modell (frei)"
        case .turkish:
            return "Groq modeli (özel)"
        case .english:
            return "Groq model (custom)"
        }
    }

    var groqModelHint: String {
        if self == .spanish {
            return "Si el modelo no está disponible, la app probará automáticamente otros modelos de Groq."
        }
        if self == .russian {
            return "Если модель недоступна, приложение автоматически попробует другие модели Groq."
        }
        if self == .ukrainian {
            return "Якщо модель недоступна, застосунок автоматично спробує інші моделі Groq."
        }
        switch localizationFamily {
        case .german:
            return "Wenn das Modell nicht verfuegbar ist, probiert die App automatisch andere Groq-Modelle."
        case .turkish:
            return "Model mevcut değilse uygulama otomatik olarak diğer Groq modellerini dener."
        case .english:
            return "If the model is unavailable, the app automatically tries other Groq models."
        }
    }

    var ollamaURLFieldTitle: String {
        if self == .spanish {
            return "URL de Ollama"
        }
        if self == .russian {
            return "URL Ollama"
        }
        if self == .ukrainian {
            return "URL Ollama"
        }
        switch localizationFamily {
        case .german:
            return "Ollama URL"
        case .turkish:
            return "Ollama URL"
        case .english:
            return "Ollama URL"
        }
    }

    var ollamaCustomModelFieldTitle: String {
        if self == .spanish {
            return "Modelo de Ollama (personalizado)"
        }
        if self == .russian {
            return "Модель Ollama (своя)"
        }
        if self == .ukrainian {
            return "Модель Ollama (власна)"
        }
        switch localizationFamily {
        case .german:
            return "Ollama Modell (frei)"
        case .turkish:
            return "Ollama modeli (özel)"
        case .english:
            return "Ollama model (custom)"
        }
    }

    var ollamaSimulatorHint: String {
        if self == .spanish {
            return "Simulador: http://127.0.0.1:11434, iPhone: http://TU-IP-MAC:11434"
        }
        if self == .russian {
            return "Симулятор: http://127.0.0.1:11434, iPhone: http://IP-ВАШЕГО-MAC:11434"
        }
        if self == .ukrainian {
            return "Симулятор: http://127.0.0.1:11434, iPhone: http://IP-ВАШОГО-MAC:11434"
        }
        switch localizationFamily {
        case .german:
            return "Simulator: http://127.0.0.1:11434, iPhone: http://DEIN-MAC-IP:11434"
        case .turkish:
            return "Simülatör: http://127.0.0.1:11434, iPhone: http://MAC-IP-ADRESIN:11434"
        case .english:
            return "Simulator: http://127.0.0.1:11434, iPhone: http://YOUR-MAC-IP:11434"
        }
    }

    var geminiCustomModelFieldTitle: String {
        if self == .spanish {
            return "Modelo de Gemini (personalizado, opcional)"
        }
        if self == .russian {
            return "Своя модель Gemini (необязательно)"
        }
        if self == .ukrainian {
            return "Власна модель Gemini (необов'язково)"
        }
        switch localizationFamily {
        case .german:
            return "Eigenes Gemini Modell (optional)"
        case .turkish:
            return "Özel Gemini modeli (isteğe bağlı)"
        case .english:
            return "Custom Gemini model (optional)"
        }
    }

    var geminiCustomModelHint: String {
        if self == .spanish {
            return "Si se define un modelo personalizado, se usará primero."
        }
        if self == .russian {
            return "Если указана своя модель, она будет использоваться в первую очередь."
        }
        if self == .ukrainian {
            return "Якщо задано власну модель, спочатку використовується вона."
        }
        switch localizationFamily {
        case .german:
            return "Wenn ein eigenes Modell eingetragen ist, wird es zuerst verwendet."
        case .turkish:
            return "Özel bir model girilmişse önce o model kullanılır."
        case .english:
            return "If a custom model is set, it is used first."
        }
    }

    var samplingSectionTitle: String {
        if self == .spanish {
            return "Muestreo"
        }
        if self == .russian {
            return "Сэмплирование"
        }
        if self == .ukrainian {
            return "Семплювання"
        }
        switch localizationFamily {
        case .german:
            return "Sampling"
        case .turkish:
            return "Örnekleme"
        case .english:
            return "Sampling"
        }
    }

    var tempLabel: String {
        if self == .spanish {
            return "Temperatura"
        }
        if self == .russian {
            return "Температура"
        }
        if self == .ukrainian {
            return "Температура"
        }
        switch localizationFamily {
        case .german:
            return "Temp"
        case .turkish:
            return "Sıcaklık"
        case .english:
            return "Temp"
        }
    }

    var tempHint: String {
        if self == .spanish {
            return "Baja = más estable, alta = más creativa."
        }
        if self == .russian {
            return "Низко = стабильнее, высоко = креативнее."
        }
        if self == .ukrainian {
            return "Низька = стабільніше, висока = креативніше."
        }
        switch localizationFamily {
        case .german:
            return "Niedrig = stabiler, hoch = kreativer."
        case .turkish:
            return "Düşük = daha stabil, yüksek = daha yaratıcı."
        case .english:
            return "Low = more stable, high = more creative."
        }
    }

    var conversationSectionTitle: String {
        if self == .spanish {
            return "Conversación"
        }
        if self == .russian {
            return "Разговор"
        }
        if self == .ukrainian {
            return "Розмова"
        }
        switch localizationFamily {
        case .german:
            return "Konversation"
        case .turkish:
            return "Konuşma"
        case .english:
            return "Conversation"
        }
    }

    var conversationLanguagePickerTitle: String {
        if self == .spanish {
            return "Idioma"
        }
        if self == .russian {
            return "Язык"
        }
        if self == .ukrainian {
            return "Мова"
        }
        switch localizationFamily {
        case .german:
            return "Sprache"
        case .turkish:
            return "Dil"
        case .english:
            return "Language"
        }
    }

    var responseLengthPickerTitle: String {
        if self == .spanish {
            return "Longitud del texto"
        }
        if self == .russian {
            return "Длина текста"
        }
        if self == .ukrainian {
            return "Довжина тексту"
        }
        switch localizationFamily {
        case .german:
            return "Textlaenge"
        case .turkish:
            return "Metin uzunluğu"
        case .english:
            return "Text length"
        }
    }

    var responseLengthHint: String {
        if self == .spanish {
            return "Corto = respuestas rápidas, Largo = respuestas mucho más detalladas."
        }
        if self == .russian {
            return "Коротко = быстрые ответы, Длинно = гораздо более подробные ответы."
        }
        if self == .ukrainian {
            return "Коротко = швидкі відповіді, Довго = значно детальніші відповіді."
        }
        switch localizationFamily {
        case .german:
            return "Kurz = schnelle Antworten, Lang = deutlich ausfuehrlichere Antworten."
        case .turkish:
            return "Kısa = hızlı cevaplar, Uzun = belirgin biçimde daha ayrıntılı cevaplar."
        case .english:
            return "Short = quick replies, Long = much more detailed replies."
        }
    }

    var hintsSectionTitle: String {
        if self == .spanish {
            return "Sugerencias"
        }
        if self == .russian {
            return "Подсказки"
        }
        if self == .ukrainian {
            return "Підказки"
        }
        switch localizationFamily {
        case .german:
            return "Hinweise"
        case .turkish:
            return "İpuçları"
        case .english:
            return "Hints"
        }
    }

    var appLanguagePickerTitle: String {
        if self == .spanish {
            return "Idioma de la app"
        }
        if self == .russian {
            return "Язык приложения"
        }
        if self == .ukrainian {
            return "Мова застосунку"
        }
        switch localizationFamily {
        case .german:
            return "Appsprache"
        case .turkish:
            return "Uygulama dili"
        case .english:
            return "App language"
        }
    }

    var audioSectionTitle: String {
        if self == .spanish {
            return "Audio"
        }
        if self == .russian {
            return "Аудио"
        }
        if self == .ukrainian {
            return "Аудіо"
        }
        switch localizationFamily {
        case .german:
            return "Audio"
        case .turkish:
            return "Ses"
        case .english:
            return "Audio"
        }
    }

    var readAnswerToggleTitle: String {
        if self == .spanish {
            return "Leer respuesta en voz alta"
        }
        if self == .russian {
            return "Озвучивать ответ"
        }
        if self == .ukrainian {
            return "Озвучувати відповідь"
        }
        switch localizationFamily {
        case .german:
            return "Antwort vorlesen"
        case .turkish:
            return "Yanıtı sesli oku"
        case .english:
            return "Read response aloud"
        }
    }

    var readAnswerHint: String {
        if self == .spanish {
            return "La voz sigue el idioma de conversación."
        }
        if self == .russian {
            return "Озвучка следует языку разговора."
        }
        if self == .ukrainian {
            return "Озвучення відповідає мові розмови."
        }
        switch localizationFamily {
        case .german:
            return "Vorlesen folgt der Konversationssprache."
        case .turkish:
            return "Sesli okuma konuşma dilini takip eder."
        case .english:
            return "Speech follows the conversation language."
        }
    }

    var speechTempoLabel: String {
        if self == .spanish {
            return "Velocidad de voz"
        }
        if self == .russian {
            return "Темп речи"
        }
        if self == .ukrainian {
            return "Темп мовлення"
        }
        switch localizationFamily {
        case .german:
            return "Sprechtempo"
        case .turkish:
            return "Konuşma hızı"
        case .english:
            return "Speech rate"
        }
    }

    var voicePickerTitle: String {
        if self == .spanish {
            return "Voz"
        }
        if self == .russian {
            return "Голос"
        }
        if self == .ukrainian {
            return "Голос"
        }
        switch localizationFamily {
        case .german:
            return "Stimme"
        case .turkish:
            return "Ses"
        case .english:
            return "Voice"
        }
    }

    var defaultVoiceLabel: String {
        if self == .spanish {
            return "Predeterminada"
        }
        if self == .russian {
            return "По умолчанию"
        }
        if self == .ukrainian {
            return "За замовчуванням"
        }
        switch localizationFamily {
        case .german:
            return "Standard"
        case .turkish:
            return "Varsayılan"
        case .english:
            return "Default"
        }
    }

    var voiceUnavailableHint: String {
        if self == .spanish {
            return "La voz guardada no está disponible en este dispositivo."
        }
        if self == .russian {
            return "Сохраненный голос недоступен на этом устройстве."
        }
        if self == .ukrainian {
            return "Збережений голос недоступний на цьому пристрої."
        }
        switch localizationFamily {
        case .german:
            return "Die gespeicherte Stimme ist auf diesem Geraet nicht verfuegbar."
        case .turkish:
            return "Kaydedilen ses bu cihazda mevcut değil."
        case .english:
            return "The saved voice is not available on this device."
        }
    }

    var testVoiceButtonTitle: String {
        if self == .spanish {
            return "Probar voz"
        }
        if self == .russian {
            return "Проверить голос"
        }
        if self == .ukrainian {
            return "Перевірити голос"
        }
        switch localizationFamily {
        case .german:
            return "Stimme testen"
        case .turkish:
            return "Sesi test et"
        case .english:
            return "Test voice"
        }
    }

    var settingsLanguageMenuLabel: String {
        if self == .spanish {
            return "Elegir idioma de la app en ajustes"
        }
        if self == .russian {
            return "Выбрать язык приложения в настройках"
        }
        if self == .ukrainian {
            return "Виберіть мову застосунку в налаштуваннях"
        }
        switch localizationFamily {
        case .german:
            return "Appsprache in Einstellungen waehlen"
        case .turkish:
            return "Ayarlarda uygulama dilini seç"
        case .english:
            return "Choose app language in settings"
        }
    }

    var backgroundSectionTitle: String {
        if self == .spanish {
            return "Fondo"
        }
        if self == .russian {
            return "Фон"
        }
        if self == .ukrainian {
            return "Тло"
        }
        switch localizationFamily {
        case .german:
            return "Hintergrund"
        case .turkish:
            return "Arka plan"
        case .english:
            return "Background"
        }
    }

    var topColorLabel: String {
        if self == .spanish {
            return "Color superior"
        }
        if self == .russian {
            return "Верхний цвет"
        }
        if self == .ukrainian {
            return "Верхній колір"
        }
        switch localizationFamily {
        case .german:
            return "Farbe oben"
        case .turkish:
            return "Üst renk"
        case .english:
            return "Top color"
        }
    }

    var bottomColorLabel: String {
        if self == .spanish {
            return "Color inferior"
        }
        if self == .russian {
            return "Нижний цвет"
        }
        if self == .ukrainian {
            return "Нижній колір"
        }
        switch localizationFamily {
        case .german:
            return "Farbe unten"
        case .turkish:
            return "Alt renk"
        case .english:
            return "Bottom color"
        }
    }

    var defaultColorsButtonTitle: String {
        if self == .spanish {
            return "Colores predeterminados"
        }
        if self == .russian {
            return "Стандартные цвета"
        }
        if self == .ukrainian {
            return "Стандартні кольори"
        }
        switch localizationFamily {
        case .german:
            return "Standardfarben"
        case .turkish:
            return "Varsayılan renkler"
        case .english:
            return "Default colors"
        }
    }

    var backgroundColorTitle: String {
        if self == .spanish {
            return "Color de fondo"
        }
        if self == .russian {
            return "Цвет фона"
        }
        if self == .ukrainian {
            return "Колір тла"
        }
        switch localizationFamily {
        case .german:
            return "Hintergrundfarbe"
        case .turkish:
            return "Arka plan rengi"
        case .english:
            return "Background color"
        }
    }

    var bubbleSectionTitle: String {
        if self == .spanish {
            return "Burbujas"
        }
        if self == .russian {
            return "Пузыри"
        }
        if self == .ukrainian {
            return "Бульбашки"
        }
        switch localizationFamily {
        case .german:
            return "Sprechblasen"
        case .turkish:
            return "Konuşma balonları"
        case .english:
            return "Speech bubbles"
        }
    }

    var meBubbleLabel: String {
        if self == .spanish {
            return "Yo"
        }
        if self == .russian {
            return "Я"
        }
        if self == .ukrainian {
            return "Я"
        }
        switch localizationFamily {
        case .german:
            return "Ich"
        case .turkish:
            return "Ben"
        case .english:
            return "Me"
        }
    }

    var trainerBubbleLabel: String {
        if self == .spanish {
            return "Entrenador"
        }
        if self == .russian {
            return "Тренер"
        }
        if self == .ukrainian {
            return "Тренер"
        }
        switch localizationFamily {
        case .german:
            return "Trainer"
        case .turkish:
            return "Eğitmen"
        case .english:
            return "Trainer"
        }
    }

    var bubbleColorTitle: String {
        if self == .spanish {
            return "Colores de burbuja"
        }
        if self == .russian {
            return "Цвета пузырей"
        }
        if self == .ukrainian {
            return "Кольори бульбашок"
        }
        switch localizationFamily {
        case .german:
            return "Blasenfarben"
        case .turkish:
            return "Balon renkleri"
        case .english:
            return "Bubble colors"
        }
    }

    func feedbackTitle(for level: UserSentenceFeedback.Level) -> String {
        if self == .spanish {
            switch level {
            case .good:
                return "Tu frase es correcta."
            case .warning:
                return "Se entiende, pero más natural sería:"
            case .bad:
                return "Hay una desviación grande. Más natural sería:"
            }
        }
        if self == .russian {
            switch level {
            case .good:
                return "Ваше предложение правильное."
            case .warning:
                return "Понятно, но естественнее будет:"
            case .bad:
                return "Сильное отклонение. Естественнее так:"
            }
        }
        switch (localizationFamily, level) {
        case (.german, .good):
            return "Dein Satz ist korrekt."
        case (.german, .warning):
            return "Verständlich, aber natürlicher wäre:"
        case (.german, .bad):
            return "Starke Abweichung. Natürlicher wäre:"

        case (.turkish, .good):
            return "Cümlen doğru."
        case (.turkish, .warning):
            return "Anlaşılır, daha doğal hali:"
        case (.turkish, .bad):
            return "Belirgin hata var, daha doğal hali:"

        case (.english, .good):
            return "Your sentence is correct."
        case (.english, .warning):
            return "Understandable, but more natural would be:"
        case (.english, .bad):
            return "Large deviation. A more natural sentence is:"
        }
    }
}

enum LanguageLevel: String, CaseIterable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"

    var id: String { rawValue }

    var promptGuidance: String {
        switch self {
        case .a1:
            return "Sehr einfache, klare Sprache mit kurzen Saetzen und alltaeglichen Woertern."
        case .a2:
            return "Einfache Alltagssprache, kurze bis mittlere Saetze, gut nachvollziehbar."
        case .b1:
            return "Natuerliche, aber noch klare Saetze mit etwas mehr Details."
        case .b2:
            return "Fluessige, differenzierte Sprache mit nuancierten Formulierungen."
        case .c1:
            return "Sehr natuerliche, praezise und abwechslungsreiche Sprache auf fortgeschrittenem Niveau."
        }
    }
}

enum TutorResponseLength: String, CaseIterable, Identifiable {
    case short = "short"
    case medium = "medium"
    case long = "long"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short: return "Kurz"
        case .medium: return "Mittel"
        case .long: return "Lang"
        }
    }

    func title(for language: AppLanguage) -> String {
        if language == .spanish {
            switch self {
            case .short: return "Corto"
            case .medium: return "Medio"
            case .long: return "Largo"
            }
        }
        if language == .russian {
            switch self {
            case .short: return "Коротко"
            case .medium: return "Средне"
            case .long: return "Длинно"
            }
        }
        if language == .ukrainian {
            switch self {
            case .short: return "Коротко"
            case .medium: return "Середньо"
            case .long: return "Довго"
            }
        }
        switch (self, language.localizationFamily) {
        case (.short, .german): return "Kurz"
        case (.medium, .german): return "Mittel"
        case (.long, .german): return "Lang"
        case (.short, .turkish): return "Kısa"
        case (.medium, .turkish): return "Orta"
        case (.long, .turkish): return "Uzun"
        case (.short, .english): return "Short"
        case (.medium, .english): return "Medium"
        case (.long, .english): return "Long"
        }
    }

    var sentenceLimit: Int {
        switch self {
        case .short: return 2
        case .medium: return 3
        case .long: return 5
        }
    }

    var wordLimit: Int {
        switch self {
        case .short: return 16
        case .medium: return 32
        case .long: return 60
        }
    }

    var characterLimit: Int {
        switch self {
        case .short: return 130
        case .medium: return 230
        case .long: return 420
        }
    }

    var promptGuidance: String {
        switch self {
        case .short:
            return "1 bis 2 kurze Saetze, maximal 16 Woerter."
        case .medium:
            return "2 bis 3 Saetze, maximal 32 Woerter."
        case .long:
            return "3 bis 5 Saetze, maximal 60 Woerter."
        }
    }
}

enum AIProvider: String, CaseIterable, Identifiable {
    case groq = "Groq (Cloud, gratis Tier)"
    case ollama = "Ollama (Lokal, gratis)"
    case gemini = "Gemini"

    var id: String { rawValue }

    func displayName(for language: AppLanguage) -> String {
        if language == .spanish {
            switch self {
            case .groq:
                return "Groq (nube, nivel gratis)"
            case .ollama:
                return "Ollama (local, gratis)"
            case .gemini:
                return "Gemini"
            }
        }
        if language == .russian {
            switch self {
            case .groq:
                return "Groq (облако, бесплатный тариф)"
            case .ollama:
                return "Ollama (локально, бесплатно)"
            case .gemini:
                return "Gemini"
            }
        }
        if language == .ukrainian {
            switch self {
            case .groq:
                return "Groq (хмара, безкоштовний тариф)"
            case .ollama:
                return "Ollama (локально, безкоштовно)"
            case .gemini:
                return "Gemini"
            }
        }
        switch (self, language.localizationFamily) {
        case (.groq, .german):
            return "Groq (Cloud, gratis Tier)"
        case (.ollama, .german):
            return "Ollama (Lokal, gratis)"
        case (.gemini, .german):
            return "Gemini"

        case (.groq, .turkish):
            return "Groq (Bulut, ücretsiz katman)"
        case (.ollama, .turkish):
            return "Ollama (Yerel, ücretsiz)"
        case (.gemini, .turkish):
            return "Gemini"

        case (.groq, .english):
            return "Groq (Cloud, free tier)"
        case (.ollama, .english):
            return "Ollama (Local, free)"
        case (.gemini, .english):
            return "Gemini"
        }
    }
}

enum KeychainStore {
    private static let service = "de.Sprachtrainer.secrets"

    static func save(value: String, for account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        SecItemDelete(query as CFDictionary)

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: Data(cleaned.utf8),
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(account: String) -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }
}

private struct PersistedColor {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var encoded: String {
        "\(red),\(green),\(blue),\(alpha)"
    }

    static func decoded(from raw: String, fallback: PersistedColor) -> PersistedColor {
        let parts = raw.split(separator: ",").map { Double($0) }
        guard parts.count == 4,
              let red = parts[0],
              let green = parts[1],
              let blue = parts[2],
              let alpha = parts[3] else {
            return fallback
        }

        return PersistedColor(
            red: red.clamped(to: 0...1),
            green: green.clamped(to: 0...1),
            blue: blue.clamped(to: 0...1),
            alpha: alpha.clamped(to: 0...1)
        )
    }

    static func from(_ color: Color, fallback: PersistedColor) -> PersistedColor {
#if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return fallback
        }
        return PersistedColor(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            alpha: Double(alpha)
        )
#elseif canImport(AppKit)
        guard let converted = NSColor(color).usingColorSpace(.sRGB) else {
            return fallback
        }
        return PersistedColor(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            alpha: Double(converted.alphaComponent)
        )
#else
        return fallback
#endif
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

@MainActor
final class SpeechOutputManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isEnabled = true
    @Published private(set) var isSpeaking = false
    @Published private(set) var isPaused = false
    @Published private(set) var activePlaybackKey = ""

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, mode: ConversationMode, rate: Float, preferredVoiceIdentifier: String?, force: Bool = false) {
        guard isEnabled || force else { return }
        activatePlaybackAudioSessionIfNeeded()
        let extractedText: String?
        let sourceKey = playbackKey(for: text)

        switch mode {
        case .russian:
            extractedText = extractRussianText(from: text)
        case .turkish:
            extractedText = extractTurkishText(from: text)
        case .english:
            extractedText = extractEnglishText(from: text)
        case .ukrainian:
            extractedText = extractUkrainianText(from: text)
        case .italian:
            extractedText = extractItalianText(from: text)
        case .spanish:
            extractedText = extractSpanishText(from: text)
        case .german:
            extractedText = extractGermanText(from: text)
        }

        let fallback = sanitizedFallbackText(from: text)
        let finalText = (extractedText ?? fallback)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        activePlaybackKey = sourceKey.isEmpty ? playbackKey(for: finalText) : sourceKey
        isPaused = false
        isSpeaking = true

        let utterance = AVSpeechUtterance(string: finalText)
        utterance.voice = preferredVoice(for: mode, preferredVoiceIdentifier: preferredVoiceIdentifier)
        utterance.rate = max(0.3, min(0.6, rate))
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
        activePlaybackKey = ""
    }

    func pause() {
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        if synthesizer.pauseSpeaking(at: .word) {
            isPaused = true
            isSpeaking = true
        }
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        if synthesizer.continueSpeaking() {
            isPaused = false
            isSpeaking = true
        }
    }

    func isPlaybackActive(for text: String) -> Bool {
        guard !activePlaybackKey.isEmpty else { return false }
        return activePlaybackKey == playbackKey(for: text)
    }

    fileprivate func handleSpeechDidStart(_ utterance: AVSpeechUtterance) {
        if activePlaybackKey.isEmpty {
            activePlaybackKey = playbackKey(for: utterance.speechString)
        }
        isSpeaking = true
        isPaused = false
    }

    fileprivate func handleSpeechDidPause() {
        isSpeaking = true
        isPaused = true
    }

    fileprivate func handleSpeechDidContinue() {
        isSpeaking = true
        isPaused = false
    }

    fileprivate func handleSpeechDidEnd() {
        isSpeaking = false
        isPaused = false
        activePlaybackKey = ""
    }

    private func activatePlaybackAudioSessionIfNeeded() {
#if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            // Fall back to current session when category switch is not possible.
        }
#endif
    }

    private func removeCorrectionLabels(from text: String) -> String {
        text
            .replacingOccurrences(of: "(?i)korrektur\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)correction\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)correzione\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)correccion\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)corrección\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)duzeltme\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)düzeltme\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)исправление\\s*:?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "(?i)виправлення\\s*:?", with: " ", options: .regularExpression)
    }

    private func extractRussianText(from text: String) -> String? {
        let withoutLabels = removeCorrectionLabels(from: text)

        let cyrillicOnly = withoutLabels.replacingOccurrences(
            of: "[^А-Яа-яЁё0-9\\s.,!?;:()«»\"'\\-—]",
            with: " ",
            options: .regularExpression
        )

        let normalized = cyrillicOnly
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil else {
            return nil
        }
        return normalized
    }

    private func extractTurkishText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)

        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        if lines.isEmpty { return nil }

        let turkishHints = [
            " merhaba ", " teşekkür ", " tesekkur ", " nasılsın ", " nasilsin ",
            " evet ", " hayır ", " hayir ", " lütfen ", " lutfen ",
            " için ", " icin ", " çok ", " cok ", " bir ",
            " mı ", " mi ", " mu ", " mü ", " ben ", " sen "
        ]
        let germanHints = [" was ", " bedeutet ", " warum ", " bitte ", " ich ", " nicht "]

        let bestLine = lines.max { lhs, rhs in
            scoreTurkishLine(lhs, turkishHints: turkishHints, germanHints: germanHints) <
            scoreTurkishLine(rhs, turkishHints: turkishHints, germanHints: germanHints)
        }

        guard let bestLine else { return nil }

        let cleaned = bestLine.replacingOccurrences(
            of: "[^A-Za-zÇĞİÖŞÜçğıöşü0-9\\s.,!?;:()\"'\\-]",
            with: " ",
            options: .regularExpression
        ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleaned.isEmpty {
            return cleaned
        }

        return sanitizedFallbackText(from: normalized)
    }

    private func extractEnglishText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)
        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let englishHints = [
            " hello ", " hi ", " i ", " you ", " are ", " is ", " can ",
            " please ", " thanks ", " want ", " today ", " what ", " where "
        ]
        let germanHints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let turkishHints = [" merhaba ", " nasılsın ", " nasilsin ", " teşekkür ", " tesekkur ", " lütfen ", " lutfen "]

        let bestLine = lines.max { lhs, rhs in
            scoreEnglishLine(lhs, englishHints: englishHints, germanHints: germanHints, turkishHints: turkishHints) <
            scoreEnglishLine(rhs, englishHints: englishHints, germanHints: germanHints, turkishHints: turkishHints)
        }

        guard let bestLine else { return nil }
        let cleaned = bestLine.replacingOccurrences(
            of: "[^A-Za-z0-9\\s.,!?;:()\"'\\-]",
            with: " ",
            options: .regularExpression
        ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.range(of: "[A-Za-z]", options: .regularExpression) != nil else {
            return nil
        }
        return cleaned
    }

    private func extractItalianText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)
        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let italianHints = [
            " ciao ", " grazie ", " per favore ", " voglio ", " oggi ",
            " domani ", " posso ", " come ", " sono ", " sei "
        ]
        let germanHints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let spanishHints = [" hola ", " gracias ", " por favor ", " quiero ", " hoy ", " manana ", " mañana "]

        let bestLine = lines.max { lhs, rhs in
            scoreItalianLine(lhs, italianHints: italianHints, germanHints: germanHints, spanishHints: spanishHints) <
            scoreItalianLine(rhs, italianHints: italianHints, germanHints: germanHints, spanishHints: spanishHints)
        }

        guard let bestLine else { return nil }
        let cleaned = bestLine.replacingOccurrences(
            of: "[^A-Za-zÀ-ÖØ-öø-ÿ0-9\\s.,!?;:()\"'\\-]",
            with: " ",
            options: .regularExpression
        ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ]", options: .regularExpression) != nil else {
            return nil
        }
        return cleaned
    }

    private func extractSpanishText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)
        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let spanishHints = [
            " hola ", " gracias ", " por favor ", " quiero ", " hoy ",
            " manana ", " mañana ", " puedo ", " como ", " estoy ", " eres "
        ]
        let germanHints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let italianHints = [" ciao ", " grazie ", " per favore ", " voglio ", " oggi ", " domani "]

        let bestLine = lines.max { lhs, rhs in
            scoreSpanishLine(lhs, spanishHints: spanishHints, germanHints: germanHints, italianHints: italianHints) <
            scoreSpanishLine(rhs, spanishHints: spanishHints, germanHints: germanHints, italianHints: italianHints)
        }

        guard let bestLine else { return nil }
        let cleaned = bestLine.replacingOccurrences(
            of: "[^A-Za-zÀ-ÖØ-öø-ÿ0-9\\s.,!?;:()\"'\\-¿¡]",
            with: " ",
            options: .regularExpression
        ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ]", options: .regularExpression) != nil else {
            return nil
        }
        return cleaned
    }

    private func extractGermanText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)
        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let germanHints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let englishHints = [" hello ", " hi ", " i ", " you ", " are ", " is ", " can ", " thanks ", " please "]
        let turkishHints = [" merhaba ", " nasılsın ", " nasilsin ", " teşekkür ", " tesekkur ", " lütfen ", " lutfen "]

        let bestLine = lines.max { lhs, rhs in
            scoreGermanLine(lhs, germanHints: germanHints, englishHints: englishHints, turkishHints: turkishHints) <
            scoreGermanLine(rhs, germanHints: germanHints, englishHints: englishHints, turkishHints: turkishHints)
        }

        guard let bestLine else { return nil }
        let cleaned = bestLine.replacingOccurrences(
            of: "[^A-Za-zÄÖÜäöüß0-9\\s.,!?;:()\"'\\-]",
            with: " ",
            options: .regularExpression
        ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.range(of: "[A-Za-zÄÖÜäöüß]", options: .regularExpression) != nil else {
            return nil
        }
        return cleaned
    }

    private func extractUkrainianText(from text: String) -> String? {
        let normalized = removeCorrectionLabels(from: text)
        let lines = normalized.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let ukrainianHints = [" привіт ", " дякую ", " будь ласка ", " так ", " ні ", " як ", " сьогодні ", " можу "]
        let russianHints = [" привет ", " спасибо ", " пожалуйста ", " сегодня ", " хорошо ", " что "]
        let germanHints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " der ", " die ", " das "]

        let preferred = lines.sorted {
            scoreUkrainianLine($0, ukrainianHints: ukrainianHints, russianHints: russianHints, germanHints: germanHints) >
            scoreUkrainianLine($1, ukrainianHints: ukrainianHints, russianHints: russianHints, germanHints: germanHints)
        }

        var fallbackCandidate: String?
        for line in preferred {
            let cleaned = line.replacingOccurrences(
                of: "[^А-Яа-яЄєІіЇїҐґ0-9\\s.,!?;:()«»\"'\\-—]",
                with: " ",
                options: .regularExpression
            ).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
             .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[А-Яа-яЄєІіЇїҐґ]", options: .regularExpression) != nil else {
                continue
            }

            if fallbackCandidate == nil {
                fallbackCandidate = cleaned
            }

            let lower = " \(cleaned.lowercased()) "
            let ukrainianHintHits = ukrainianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            let russianHintHits = russianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            let ukrainianSpecificCount = matchCount(in: cleaned, pattern: "[ЄєІіЇїҐґ]")
            let russianSpecificCount = matchCount(in: cleaned, pattern: "[ЫыЭэЁёЪъ]")
            let ukrainianScore = scoreUkrainianLine(
                cleaned,
                ukrainianHints: ukrainianHints,
                russianHints: russianHints,
                germanHints: germanHints
            )

            let hasUkrainianEvidence = ukrainianSpecificCount > 0 || ukrainianHintHits > russianHintHits
            if hasUkrainianEvidence && russianSpecificCount == 0 {
                return cleaned
            }
            if ukrainianHintHits >= 1 && russianHintHits == 0 && russianSpecificCount <= 1 {
                return cleaned
            }
            if russianSpecificCount == 0 && ukrainianScore >= 6 {
                return cleaned
            }
        }

        return fallbackCandidate
    }

    private func scoreTurkishLine(_ line: String, turkishHints: [String], germanHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let turkishHintHits = turkishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let turkishCharCount = matchCount(in: line, pattern: "[ÇĞİÖŞÜçğıöşü]")
        let latinCount = matchCount(in: line, pattern: "[A-Za-zÇĞİÖŞÜçğıöşü]")
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")

        return (turkishHintHits * 7) + (turkishCharCount * 3) + latinCount - (germanHintHits * 2) - (cyrillicCount * 6)
    }

    private func scoreEnglishLine(_ line: String, englishHints: [String], germanHints: [String], turkishHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let englishHintHits = englishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let turkishHintHits = turkishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latinCount = matchCount(in: line, pattern: "[A-Za-z]")
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        let turkishCharCount = matchCount(in: line, pattern: "[ÇĞİÖŞÜçğıöşü]")

        return (englishHintHits * 8) + latinCount - (germanHintHits * 4) - (turkishHintHits * 4) - (cyrillicCount * 10) - (turkishCharCount * 3)
    }

    private func scoreUkrainianLine(_ line: String, ukrainianHints: [String], russianHints: [String], germanHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let ukrainianHintHits = ukrainianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let russianHintHits = russianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЄєІіЇїҐґ]")
        let ukrainianCharCount = matchCount(in: line, pattern: "[ЄєІіЇїҐґ]")
        let russianSpecificCount = matchCount(in: line, pattern: "[ЫыЭэЁёЪъ]")
        let latinCount = matchCount(in: line, pattern: "[A-Za-zÄÖÜäöüßÇĞİÖŞÜçğıöşü]")

        return (ukrainianHintHits * 8) + (ukrainianCharCount * 5) + cyrillicCount - (russianHintHits * 4) - (russianSpecificCount * 9) - (germanHintHits * 4) - (latinCount * 6)
    }

    private func scoreItalianLine(_ line: String, italianHints: [String], germanHints: [String], spanishHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let italianHintHits = italianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let spanishHintHits = spanishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latinCount = matchCount(in: line, pattern: "[A-Za-zÀ-ÖØ-öø-ÿ]")
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (italianHintHits * 8) + latinCount - (germanHintHits * 4) - (spanishHintHits * 3) - (cyrillicCount * 8)
    }

    private func scoreSpanishLine(_ line: String, spanishHints: [String], germanHints: [String], italianHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let spanishHintHits = spanishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let italianHintHits = italianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latinCount = matchCount(in: line, pattern: "[A-Za-zÀ-ÖØ-öø-ÿ]")
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (spanishHintHits * 8) + latinCount - (germanHintHits * 4) - (italianHintHits * 3) - (cyrillicCount * 8)
    }

    private func scoreGermanLine(_ line: String, germanHints: [String], englishHints: [String], turkishHints: [String]) -> Int {
        let lower = " \(line.lowercased()) "
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let englishHintHits = englishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let turkishHintHits = turkishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanChars = matchCount(in: line, pattern: "[ÄÖÜäöüß]")
        let latinCount = matchCount(in: line, pattern: "[A-Za-zÄÖÜäöüß]")
        let cyrillicCount = matchCount(in: line, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (germanHintHits * 8) + (germanChars * 3) + latinCount - (englishHintHits * 4) - (turkishHintHits * 4) - (cyrillicCount * 8)
    }

    private func matchCount(in text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, options: [], range: range)
    }

    private func sanitizedFallbackText(from text: String) -> String {
        text
            .replacingOccurrences(of: "[^\\p{L}0-9\\s.,!?;:()\"'\\-]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func playbackKey(for text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive], locale: Locale.current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func preferredVoice(for mode: ConversationMode, preferredVoiceIdentifier: String?) -> AVSpeechSynthesisVoice? {
        let customIdentifier = preferredVoiceIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !customIdentifier.isEmpty,
           let customVoice = AVSpeechSynthesisVoice(identifier: customIdentifier),
           customVoice.language.lowercased().hasPrefix(mode.speechLanguagePrefix.lowercased()) {
            return customVoice
        }

        switch mode {
        case .ukrainian:
            if let ukrainianVoice = AVSpeechSynthesisVoice(language: mode.speechLocaleIdentifier) {
                return ukrainianVoice
            }
            if let prefixVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
                $0.language.lowercased().hasPrefix(mode.speechLanguagePrefix)
            }) {
                return prefixVoice
            }
            return AVSpeechSynthesisVoice(language: "ru-RU")
                ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.lowercased().hasPrefix("ru") })
        default:
            return AVSpeechSynthesisVoice(language: mode.speechLocaleIdentifier)
                ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.lowercased().hasPrefix(mode.speechLanguagePrefix) })
        }
    }
}

extension SpeechOutputManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSpeechDidStart(utterance)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSpeechDidPause()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSpeechDidContinue()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSpeechDidEnd()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSpeechDidEnd()
        }
    }
}

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    private var audioEngine = AVAudioEngine()

    private var primaryRecognizer: SFSpeechRecognizer?
    private var germanRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus
    private var useGermanFallback = false

    private var primaryRequest: SFSpeechAudioBufferRecognitionRequest?
    private var germanRequest: SFSpeechAudioBufferRecognitionRequest?
    private var primaryTask: SFSpeechRecognitionTask?
    private var germanTask: SFSpeechRecognitionTask?

    private var primaryTranscript = ""
    private var germanTranscript = ""
    private var primaryFinalTranscript = ""
    private var germanFinalTranscript = ""
    private var activeMode: ConversationMode = .russian

    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published var errorMessage = ""
    @Published var audioLevel: CGFloat = 0

    override init() {
        speechAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
        super.init()
    }

    func start(for mode: ConversationMode, includeGermanFallback: Bool) {
        activeMode = mode
        useGermanFallback = includeGermanFallback
        guard !isRecording else { return }
        errorMessage = ""
        recognizedText = ""
        speechAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()

        switch speechAuthorizationStatus {
        case .authorized:
            startRecording()
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    self.speechAuthorizationStatus = authStatus
                    guard authStatus == .authorized else {
                        self.errorMessage = "Bitte Spracherkennung in den iOS-Einstellungen erlauben."
                        return
                    }
                    self.startRecording()
                }
            }
        case .denied, .restricted:
            errorMessage = "Bitte Spracherkennung in den iOS-Einstellungen erlauben."
        @unknown default:
            errorMessage = "Spracherkennung ist gerade nicht verfügbar."
        }
    }

    private func startRecording() {
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 17.0, *) {
                switch AVAudioApplication.shared.recordPermission {
                case .denied:
                    errorMessage = "Mikrofon ist deaktiviert. Erlaube es in Einstellungen > Datenschutz > Mikrofon."
                    return
                case .undetermined:
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                self.startRecording()
                            } else {
                                self.errorMessage = "Mikrofon-Zugriff wurde abgelehnt."
                            }
                        }
                    }
                    return
                case .granted:
                    break
                @unknown default:
                    break
                }
            } else {
                switch audioSession.recordPermission {
                case .denied:
                    errorMessage = "Mikrofon ist deaktiviert. Erlaube es in Einstellungen > Datenschutz > Mikrofon."
                    return
                case .undetermined:
                    audioSession.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                self.startRecording()
                            } else {
                                self.errorMessage = "Mikrofon-Zugriff wurde abgelehnt."
                            }
                        }
                    }
                    return
                case .granted:
                    break
                @unknown default:
                    break
                }
            }
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers]
            )
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            primaryRecognizer = SFSpeechRecognizer(locale: Locale(identifier: activeMode.speechLocaleIdentifier))
            finalizeRecognitionTasks()
            primaryRequest = nil
            germanRequest = nil
            primaryTranscript = ""
            germanTranscript = ""
            primaryFinalTranscript = ""
            germanFinalTranscript = ""
            recognizedText = ""

            primaryRequest = SFSpeechAudioBufferRecognitionRequest()
            germanRequest = useGermanFallback ? SFSpeechAudioBufferRecognitionRequest() : nil
            primaryRequest?.shouldReportPartialResults = true
            germanRequest?.shouldReportPartialResults = useGermanFallback
            primaryRequest?.taskHint = .dictation
            germanRequest?.taskHint = useGermanFallback ? .dictation : .unspecified
            primaryRequest?.requiresOnDeviceRecognition = false
            germanRequest?.requiresOnDeviceRecognition = false
            let primaryContextHints = contextualHints(for: activeMode)
            if !primaryContextHints.isEmpty {
                primaryRequest?.contextualStrings = primaryContextHints
            }

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard format.sampleRate > 0 else {
                errorMessage = "Mikrofon nicht bereit."
                return
            }

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                self.primaryRequest?.append(buffer)
                if self.useGermanFallback {
                    self.germanRequest?.append(buffer)
                }
                let level = self.normalizedAudioLevel(from: buffer)
                Task { @MainActor in
                    self.audioLevel = (self.audioLevel * 0.35) + (level * 0.65)
                }
            }

            primaryTask?.cancel()
            germanTask?.cancel()
            primaryTask = nil
            germanTask = nil

            if let primaryRecognizer, primaryRecognizer.isAvailable, let primaryRequest {
                primaryTask = primaryRecognizer.recognitionTask(with: primaryRequest) { [weak self] result, error in
                    guard let self else { return }
                    if let result {
                        let transcript = result.bestTranscription.formattedString
                        self.primaryTranscript = transcript
                        if result.isFinal {
                            self.primaryFinalTranscript = transcript
                        }
                    }
                    if let error, self.primaryTranscript.isEmpty, self.primaryFinalTranscript.isEmpty {
                        self.errorMessage = "Spracherkennung: \(error.localizedDescription)"
                    }
                }
            }

            if useGermanFallback, let germanRecognizer, germanRecognizer.isAvailable, let germanRequest {
                germanTask = germanRecognizer.recognitionTask(with: germanRequest) { [weak self] result, _ in
                    guard let self, let result else { return }
                    let transcript = result.bestTranscription.formattedString
                    self.germanTranscript = transcript
                    if result.isFinal {
                        self.germanFinalTranscript = transcript
                    }
                }
            }

            if primaryTask == nil && germanTask == nil {
                errorMessage = "Spracherkennung ist gerade nicht verfügbar."
                return
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio-Start fehlgeschlagen: \(error.localizedDescription)"
            stop()
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        primaryRequest?.endAudio()
        germanRequest?.endAudio()

        isRecording = false

        // Keep tasks alive briefly so final words can arrive after button release.
        DispatchQueue.main.asyncAfter(deadline: .now() + recognitionSettleDelay) { [weak self] in
            guard let self, !self.isRecording else { return }
            self.primaryRequest = nil
            self.germanRequest = nil
            self.finalizeRecognitionTasks()
            self.audioLevel = 0
        }
    }

    func consumeBestTranscriptAfterStop(for mode: ConversationMode) async -> String {
        let start = Date()
        while Date().timeIntervalSince(start) < recognitionSettleDelay {
            if !primaryFinalTranscript.isEmpty || !germanFinalTranscript.isEmpty {
                break
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        return consumeBestTranscript(for: mode)
    }

    func consumeBestTranscript(for mode: ConversationMode) -> String {
        let primarySource = primaryFinalTranscript.isEmpty ? primaryTranscript : primaryFinalTranscript
        let germanSource = germanFinalTranscript.isEmpty ? germanTranscript : germanFinalTranscript
        let primary = primarySource.trimmingCharacters(in: .whitespacesAndNewlines)
        let german = germanSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let chosen: String
        if useGermanFallback {
            chosen = chooseTranscript(primary: primary, german: german, mode: mode)
        } else {
            chosen = primary.isEmpty ? german : primary
        }
        recognizedText = chosen
        primaryTranscript = ""
        germanTranscript = ""
        primaryFinalTranscript = ""
        germanFinalTranscript = ""
        finalizeRecognitionTasks()
        audioLevel = 0
        return chosen
    }

    private var recognitionSettleDelay: TimeInterval {
        useGermanFallback ? 1.6 : 0.9
    }

    private func chooseTranscript(primary: String, german: String, mode: ConversationMode) -> String {
        if primary.isEmpty { return german }
        if german.isEmpty { return primary }

        switch mode {
        case .russian, .ukrainian:
            return chooseTranscriptForCyrillicMode(primary: primary, german: german)
        case .turkish, .english, .italian, .spanish, .german:
            return shouldPreferGermanTranscript(german, over: primary) ? german : primary
        }
    }

    private func chooseTranscriptForCyrillicMode(primary: String, german: String) -> String {
        let primaryCyrillicCount = countMatches(in: primary, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        let germanCyrillicCount = countMatches(in: german, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        let germanLikelihood = germanScore(for: german)
        let primaryGermanLikelihood = germanScore(for: primary)

        // If primary has clear Cyrillic content, prefer it aggressively.
        if primaryCyrillicCount >= 2 && primaryCyrillicCount >= germanCyrillicCount {
            return primary
        }

        // If primary has at least some Cyrillic and German transcript has none,
        // use primary unless German is overwhelmingly clear and primary is tiny noise.
        if primaryCyrillicCount >= 1 && germanCyrillicCount == 0 {
            if germanLikelihood >= 6 && primaryCyrillicCount == 1 && primary.count <= 4 {
                return german
            }
            return primary
        }

        // If both are Latin-only, switch to German only when it is clearly German.
        if primaryCyrillicCount == 0 && germanCyrillicCount == 0 {
            if germanLikelihood >= 6 && germanLikelihood >= primaryGermanLikelihood + 2 {
                return german
            }
            return primary.count >= german.count ? primary : german
        }

        // Rare case: German recognizer returned stronger Cyrillic.
        if germanCyrillicCount >= 2 && germanCyrillicCount > primaryCyrillicCount {
            return german
        }

        return primary
    }

    private func shouldPreferGermanTranscript(_ german: String, over primary: String) -> Bool {
        let germanLikelihood = germanScore(for: german)
        let primaryGermanLikelihood = germanScore(for: primary)
        if germanLikelihood >= 3 && germanLikelihood > primaryGermanLikelihood {
            return true
        }
        if germanLikelihood >= 4 && german.count >= primary.count {
            return true
        }
        return false
    }

    private func germanScore(for text: String) -> Int {
        let lower = " \(text.lowercased()) "
        let hints = [" ich ", " nicht ", " was ", " wie ", " warum ", " bitte ", " deutsch ", " verstehe ", " bedeut", " uebersetz", " erklär", " und ", " der ", " die ", " das "]
        let hintHits = hints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let umlautHits = countMatches(in: text, pattern: "[ÄÖÜäöüß]")
        return (hintHits * 2) + umlautHits
    }

    private func countMatches(in text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, options: [], range: range)
    }

    private func contextualHints(for mode: ConversationMode) -> [String] {
        switch mode {
        case .russian:
            return [
                "привет", "как дела", "спасибо", "пожалуйста", "я хочу",
                "мне нужно", "сегодня", "завтра", "работа", "дом", "семья"
            ]
        case .ukrainian:
            return [
                "привіт", "як справи", "дякую", "будь ласка", "я хочу",
                "мені потрібно", "сьогодні", "завтра", "робота", "дім", "сім'я"
            ]
        case .turkish:
            return ["merhaba", "nasilsin", "tesekkur ederim", "lutfen", "bugun", "yarin", "is", "ev"]
        case .english:
            return ["hello", "how are you", "thank you", "please", "today", "tomorrow", "work", "home"]
        case .italian:
            return ["ciao", "come stai", "grazie", "per favore", "oggi", "domani", "lavoro", "casa"]
        case .spanish:
            return ["hola", "como estas", "gracias", "por favor", "hoy", "manana", "trabajo", "casa"]
        case .german:
            return ["hallo", "wie geht es dir", "danke", "bitte", "heute", "morgen", "arbeit", "zuhause"]
        }
    }

    private func normalizedAudioLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        let samples = channelData[0]
        var sum: Float = 0
        for i in 0..<frameCount {
            let sample = samples[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameCount))
        let db = 20 * log10(max(rms, 0.000_02))
        let normalized = max(0, min(1, (db + 50) / 50))
        return CGFloat(normalized)
    }

    private func finalizeRecognitionTasks() {
        primaryTask?.cancel()
        germanTask?.cancel()
        primaryTask = nil
        germanTask = nil
    }
}

struct GeminiService {
    struct APIResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }

    struct APIErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String
        }
        let error: APIError
    }

    let apiKey: String
    let preferredModel: String?
    let temperature: Double
    private let fallbackModels = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-flash-latest"]

    func generate(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein Gemini API-Key gesetzt."])
        }

        var lastError: NSError?
        var models = [String]()
        if let preferred = preferredModel?.trimmingCharacters(in: .whitespacesAndNewlines), !preferred.isEmpty {
            models.append(preferred)
        }
        for model in fallbackModels where !models.contains(model) {
            models.append(model)
        }

        for model in models {
            let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
            guard let url = URL(string: endpoint) else {
                continue
            }

            let body: [String: Any] = [
                "contents": [[
                    "parts": [["text": prompt]]
                ]],
                "generationConfig": [
                    "temperature": max(0.0, min(2.0, temperature))
                ]
            ]

            let data = try JSONSerialization.data(withJSONObject: body)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = NSError(domain: "GeminiService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Keine gültige Antwort vom Server."])
                continue
            }

            if httpResponse.statusCode == 404 {
                continue
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: responseData)
                let message = apiError?.error.message ?? "HTTP \(httpResponse.statusCode)"
                throw NSError(domain: "GeminiService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }

            let decoded = try JSONDecoder().decode(APIResponse.self, from: responseData)
            if let text = decoded.candidates?.first?.content?.parts?.compactMap({ $0.text }).joined(separator: "\n"), !text.isEmpty {
                return text
            }
        }

        if let lastError {
            throw lastError
        }
        throw NSError(domain: "GeminiService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kein kompatibles Gemini-Modell verfügbar."])
    }
}

struct OllamaService {
    struct GenerateResponse: Decodable {
        let response: String?
        let error: String?
    }

    let baseURL: String
    let model: String
    let temperature: Double

    func generate(prompt: String) async throws -> String {
        let base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !base.isEmpty else {
            throw NSError(domain: "OllamaService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ollama-URL fehlt."])
        }
        guard !model.isEmpty else {
            throw NSError(domain: "OllamaService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ollama-Modell fehlt."])
        }

        let endpoint = base.hasSuffix("/") ? "\(base)api/generate" : "\(base)/api/generate"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "OllamaService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ungültige Ollama-URL."])
        }

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": max(0.0, min(2.0, temperature))
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OllamaService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Keine gültige Antwort von Ollama."])
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let decoded = try? JSONDecoder().decode(GenerateResponse.self, from: responseData)
            let message = decoded?.error ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "OllamaService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: responseData)
        let answer = (decoded.response ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !answer.isEmpty {
            return answer
        }
        throw NSError(domain: "OllamaService", code: 5, userInfo: [NSLocalizedDescriptionKey: decoded.error ?? "Ollama hat keinen Text zurückgegeben."])
    }
}

struct GroqService {
    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
        let error: GroqError?
    }

    struct GroqError: Decodable {
        let message: String
    }

    struct APIErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String?
        }
        let error: APIError?
        let message: String?
    }

    let apiKey: String
    let preferredModel: String?
    let temperature: Double
    private let fallbackModels = [
        "openai/gpt-oss-20b",
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
        "mixtral-8x7b-32768"
    ]

    func generate(prompt: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let preferred = preferredModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !key.isEmpty else {
            throw NSError(domain: "GroqService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Groq API-Key fehlt."])
        }

        var models = [String]()
        if !preferred.isEmpty {
            models.append(preferred)
        }
        for fallback in fallbackModels where !models.contains(fallback) {
            models.append(fallback)
        }
        guard !models.isEmpty else {
            throw NSError(domain: "GroqService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Groq Modell fehlt."])
        }

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw NSError(domain: "GroqService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ungültige Groq-URL."])
        }

        var lastError: NSError?

        for model in models {
            let body: [String: Any] = [
                "model": model,
                "messages": [["role": "user", "content": prompt]],
                "temperature": max(0.0, min(2.0, temperature))
            ]

            let data = try JSONSerialization.data(withJSONObject: body)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.httpBody = data

            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = NSError(
                    domain: "GroqService",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Keine gültige Antwort von Groq."]
                )
                continue
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let message = parseErrorMessage(responseData, statusCode: httpResponse.statusCode)
                if shouldFallbackToNextModel(statusCode: httpResponse.statusCode, message: message) {
                    lastError = NSError(
                        domain: "GroqService",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "\(message) (Modell: \(model))"]
                    )
                    continue
                }
                throw NSError(
                    domain: "GroqService",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "\(message) (Modell: \(model))"]
                )
            }

            let decoded = try JSONDecoder().decode(ChatResponse.self, from: responseData)
            let answer = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !answer.isEmpty {
                return answer
            }

            lastError = NSError(
                domain: "GroqService",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Groq hat keinen Text zurückgegeben. (Modell: \(model))"]
            )
        }

        if let lastError {
            throw lastError
        }
        throw NSError(domain: "GroqService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kein kompatibles Groq-Modell verfügbar."])
    }

    private func parseErrorMessage(_ responseData: Data, statusCode: Int) -> String {
        if let decoded = try? JSONDecoder().decode(ChatResponse.self, from: responseData), let message = decoded.error?.message, !message.isEmpty {
            return message
        }

        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: responseData) {
            if let message = decoded.error?.message, !message.isEmpty {
                return message
            }
            if let message = decoded.message, !message.isEmpty {
                return message
            }
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
            if let error = jsonObject["error"] as? [String: Any],
               let message = error["message"] as? String,
               !message.isEmpty {
                return message
            }
            if let message = jsonObject["message"] as? String, !message.isEmpty {
                return message
            }
        }

        return "HTTP \(statusCode)"
    }

    private func shouldFallbackToNextModel(statusCode: Int, message: String) -> Bool {
        if statusCode == 404 { return true }
        let lower = message.lowercased()
        if statusCode == 400 || statusCode == 403 {
            if lower.contains("model") && (
                lower.contains("not found")
                || lower.contains("not exist")
                || lower.contains("decommission")
                || lower.contains("unsupported")
                || lower.contains("not permitted")
                || lower.contains("invalid model")
            ) {
                return true
            }
        }
        return false
    }
}

struct ContentView: View {
    private struct ParsedTutorResponse {
        let visibleText: String
        let feedback: UserSentenceFeedback?
    }

    private struct ImportedContext: Equatable {
        let name: String
        let text: String
        let sectionIndex: Int
        let totalSections: Int

        var sectionLabel: String {
            "\(sectionIndex)/\(max(totalSections, 1))"
        }
    }

    private static let defaultBackgroundTopColor = PersistedColor(red: 0.95, green: 0.98, blue: 1.00, alpha: 1.00)
    private static let defaultBackgroundBottomColor = PersistedColor(red: 0.87, green: 0.94, blue: 0.99, alpha: 1.00)
    private static let defaultUserBubbleColor = PersistedColor(red: 0.06, green: 0.53, blue: 0.45, alpha: 1.00)
    private static let defaultTutorBubbleColor = PersistedColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90)

    @StateObject private var speechManager = SpeechManager()
    @StateObject private var speechOutput = SpeechOutputManager()
    @FocusState private var isInputFocused: Bool
    @AppStorage("ai_provider") private var storedAIProvider = AIProvider.groq.rawValue
    @State private var geminiApiKeyInput = ""
    @State private var groqApiKeyInput = ""
    @AppStorage("gemini_model_preset") private var storedGeminiModelPreset = "__auto__"
    @AppStorage("gemini_model_custom") private var storedGeminiCustomModel = ""
    @AppStorage("groq_model") private var storedGroqModel = "openai/gpt-oss-20b"
    @AppStorage("ollama_base_url") private var storedOllamaBaseURL = "http://127.0.0.1:11434"
    @AppStorage("ollama_model") private var storedOllamaModel = "llama3.2:3b"
    @AppStorage("conversation_mode") private var storedConversationMode = ConversationMode.russian.rawValue
    @State private var messages: [Message] = []
    @State private var typedText = ""
    @State private var isSending = false
    @State private var queuedUserInputs: [String] = []
    @State private var hasStartedConversation = false
    @State private var expandedFeedbackMessageID: UUID?
    @State private var translatingTutorBubbleMessageID: UUID?
    @State private var translatedTutorBubbleMessageID: UUID?
    @State private var translatedTutorBubbleText = ""
    @State private var translationRequestNonce = 0
    @State private var showBackgroundColorSheet = false
    @State private var showBubbleColorSheet = false
    @State private var showSettingsSheet = false
    @State private var showDocumentImporter = false
    @State private var isDocumentDropTargeted = false
    @State private var importTargetMode: ConversationMode?
    @AppStorage("background_top_color") private var storedBackgroundTopColor = ContentView.defaultBackgroundTopColor.encoded
    @AppStorage("background_bottom_color") private var storedBackgroundBottomColor = ContentView.defaultBackgroundBottomColor.encoded
    @AppStorage("user_bubble_color") private var storedUserBubbleColor = ContentView.defaultUserBubbleColor.encoded
    @AppStorage("tutor_bubble_color") private var storedTutorBubbleColor = ContentView.defaultTutorBubbleColor.encoded
    @State private var backgroundTopColor = ContentView.defaultBackgroundTopColor.color
    @State private var backgroundBottomColor = ContentView.defaultBackgroundBottomColor.color
    @State private var userBubbleColor = ContentView.defaultUserBubbleColor.color
    @State private var tutorBubbleColor = ContentView.defaultTutorBubbleColor.color
    @State private var activeRequestID = UUID()
    @State private var importedContextsByMode: [ConversationMode: ImportedContext] = [:]
    @State private var importedLearningModeByMode: [ConversationMode: MaterialLearningMode] = [:]
    @State private var contextStatusByMode: [ConversationMode: String] = [:]
    @State private var showMaterialLearningModeDialog = false
    @State private var pendingMaterialLearningModeTarget: ConversationMode?
    @State private var pendingMaterialLearningFileName = ""
    @State private var isAwaitingSpeechResult = false
    @State private var speechDotCount = 1
    @State private var waveformPhase = 0
    @State private var scrollToBottomSignal = 0
    @AppStorage("conversation_topic") private var storedConversationTopic = ConversationTopic.automatic.rawValue
    @AppStorage("language_level") private var storedLanguageLevel = LanguageLevel.a1.rawValue
    @AppStorage("response_length_mode") private var storedResponseLengthMode = TutorResponseLength.medium.rawValue
    @AppStorage("app_language") private var storedAppLanguage = AppLanguage.german.rawValue
    @AppStorage("model_temperature") private var storedModelTemperature = 0.70
    @AppStorage("speech_rate") private var storedSpeechRate = 0.48
    @AppStorage("speech_voice_russian") private var storedSpeechVoiceRussian = ""
    @AppStorage("speech_voice_turkish") private var storedSpeechVoiceTurkish = ""
    @AppStorage("speech_voice_english") private var storedSpeechVoiceEnglish = ""
    @AppStorage("speech_voice_ukrainian") private var storedSpeechVoiceUkrainian = ""
    @AppStorage("speech_voice_italian") private var storedSpeechVoiceItalian = ""
    @AppStorage("speech_voice_spanish") private var storedSpeechVoiceSpanish = ""
    @AppStorage("speech_voice_german") private var storedSpeechVoiceGerman = ""
    private let geminiKeychainAccount = "gemini_api_key"
    private let groqKeychainAccount = "groq_api_key"
    private let chatBottomID = "chat_bottom_anchor"
    private let speechAnimationTimer = Timer.publish(every: 0.28, on: .main, in: .common).autoconnect()
    private let automaticGeminiModel = "__auto__"
    private let geminiModelSuggestions = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.5-pro",
        "gemini-flash-latest"
    ]
    private let groqModelSuggestions = [
        "openai/gpt-oss-20b",
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
        "mixtral-8x7b-32768",
        "gemma2-9b-it"
    ]
    private let ollamaModelSuggestions = [
        "llama3.2:3b",
        "llama3.2:1b",
        "qwen2.5:3b",
        "mistral:7b",
        "gemma2:2b"
    ]

    private var effectiveGeminiApiKey: String {
        let fromKeychain = geminiApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fromKeychain.isEmpty {
            return fromKeychain
        }

        let fromInfo = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if fromInfo.isEmpty || fromInfo.contains("$(") {
            return ""
        }
        return fromInfo
    }

    private var effectiveGeminiModel: String? {
        let custom = storedGeminiCustomModel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty {
            return custom
        }

        let preset = storedGeminiModelPreset.trimmingCharacters(in: .whitespacesAndNewlines)
        if preset.isEmpty || preset == automaticGeminiModel {
            return nil
        }
        return preset
    }

    private var conversationMode: ConversationMode {
        ConversationMode.fromStoredValue(storedConversationMode)
    }

    private var aiProvider: AIProvider {
        AIProvider(rawValue: storedAIProvider) ?? .groq
    }

    private var languageLevel: LanguageLevel {
        LanguageLevel(rawValue: storedLanguageLevel) ?? .a1
    }

    private var responseLengthMode: TutorResponseLength {
        TutorResponseLength(rawValue: storedResponseLengthMode) ?? .medium
    }

    private var appLanguage: AppLanguage {
        AppLanguage.fromStoredValue(storedAppLanguage)
    }

    private var modelTemperature: Double {
        storedModelTemperature.clamped(to: 0.0...2.0)
    }

    private var modelTemperatureBinding: Binding<Double> {
        Binding(
            get: {
                modelTemperature
            },
            set: { newValue in
                storedModelTemperature = newValue.clamped(to: 0.0...2.0)
            }
        )
    }

    private var speechRate: Float {
        Float(storedSpeechRate)
    }

    private var selectedSpeechVoiceIdentifier: String {
        switch conversationMode {
        case .russian:
            return storedSpeechVoiceRussian
        case .turkish:
            return storedSpeechVoiceTurkish
        case .english:
            return storedSpeechVoiceEnglish
        case .ukrainian:
            return storedSpeechVoiceUkrainian
        case .italian:
            return storedSpeechVoiceItalian
        case .spanish:
            return storedSpeechVoiceSpanish
        case .german:
            return storedSpeechVoiceGerman
        }
    }

    private var selectedSpeechVoiceBinding: Binding<String> {
        Binding(
            get: {
                selectedSpeechVoiceIdentifier
            },
            set: { newValue in
                switch conversationMode {
                case .russian:
                    storedSpeechVoiceRussian = newValue
                case .turkish:
                    storedSpeechVoiceTurkish = newValue
                case .english:
                    storedSpeechVoiceEnglish = newValue
                case .ukrainian:
                    storedSpeechVoiceUkrainian = newValue
                case .italian:
                    storedSpeechVoiceItalian = newValue
                case .spanish:
                    storedSpeechVoiceSpanish = newValue
                case .german:
                    storedSpeechVoiceGerman = newValue
                }
            }
        )
    }

    private func sortedVoices(_ voices: [AVSpeechSynthesisVoice]) -> [AVSpeechSynthesisVoice] {
        voices.sorted {
            if $0.language == $1.language {
                if $0.name == $1.name {
                    return $0.identifier < $1.identifier
                }
                return $0.name < $1.name
            }
            return $0.language < $1.language
        }
    }

    private var availableSpeechVoicesForMode: [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let modeVoices = allVoices.filter { $0.language.lowercased().hasPrefix(conversationMode.speechLanguagePrefix) }
        return sortedVoices(modeVoices)
    }

    private func sanitizeSelectedVoiceForCurrentMode() {
        let identifier = selectedSpeechVoiceIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty else { return }
        guard let selectedVoice = AVSpeechSynthesisVoice(identifier: identifier) else {
            selectedSpeechVoiceBinding.wrappedValue = ""
            return
        }
        let expectedPrefix = conversationMode.speechLanguagePrefix.lowercased()
        if !selectedVoice.language.lowercased().hasPrefix(expectedPrefix) {
            selectedSpeechVoiceBinding.wrappedValue = ""
        }
    }

    private var conversationLanguageName: String {
        switch conversationMode {
        case .russian: return "Russisch"
        case .turkish: return "Türkisch"
        case .english: return "Englisch"
        case .ukrainian: return "Ukrainisch"
        case .italian: return "Italienisch"
        case .spanish: return "Spanisch"
        case .german: return "Deutsch"
        }
    }

    private func flag(for mode: ConversationMode) -> String {
        switch mode {
        case .russian: return "🇷🇺"
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        case .ukrainian: return "🇺🇦"
        case .italian: return "🇮🇹"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        }
    }

    private var conversationFlag: String {
        flag(for: conversationMode)
    }

    private func code(for mode: ConversationMode) -> String {
        switch mode {
        case .russian: return "RU"
        case .turkish: return "TR"
        case .english: return "EN"
        case .ukrainian: return "UA"
        case .italian: return "IT"
        case .spanish: return "ES"
        case .german: return "DE"
        }
    }

    private var explanationLanguages: String {
        switch conversationMode {
        case .russian: return "Deutsch und Türkisch"
        case .turkish: return "Deutsch und Ukrainisch"
        case .english: return "Deutsch und Russisch"
        case .ukrainian: return "Deutsch und Englisch"
        case .italian: return "Deutsch und Englisch"
        case .spanish: return "Deutsch und Englisch"
        case .german: return "Englisch und Türkisch"
        }
    }

    private var currentImportedContext: ImportedContext? {
        importedContextsByMode[conversationMode]
    }

    private var importedContextName: String {
        currentImportedContext?.name ?? ""
    }

    private var importedContextText: String {
        currentImportedContext?.text ?? ""
    }

    private func sectionLabel(for mode: ConversationMode) -> String {
        importedContextsByMode[mode]?.sectionLabel ?? "1/1"
    }

    private func activeSectionStatusText(for mode: ConversationMode) -> String {
        let section = sectionLabel(for: mode)
        if appLanguage == .ukrainian {
            return "Активний розділ: \(section)."
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Aktiver Abschnitt: \(section)."
        case .turkish:
            return "Aktif bölüm: \(section)."
        case .english:
            return "Active section: \(section)."
        }
    }

    private var contextStatusMessage: String {
        contextStatusByMode[conversationMode] ?? ""
    }

    private var hasImportedContext: Bool {
        !importedContextText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedMaterialLearningMode: MaterialLearningMode? {
        importedLearningModeByMode[conversationMode]
    }

    private var materialLearningChoiceTitle: String {
        if appLanguage == .ukrainian {
            return "Режим навчання за матеріалом"
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Material-Lernmodus"
        case .turkish:
            return "Materyal Öğrenme Modu"
        case .english:
            return "Material Learning Mode"
        }
    }

    private var learnVocabularyChoiceLabel: String {
        if appLanguage == .ukrainian {
            return "Вчити слова"
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Vokabeln lernen"
        case .turkish:
            return "Kelime çalış"
        case .english:
            return "Learn vocabulary"
        }
    }

    private var learnSentencesChoiceLabel: String {
        if appLanguage == .ukrainian {
            return "Вчити речення"
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Sätze lernen"
        case .turkish:
            return "Cümle çalış"
        case .english:
            return "Learn sentences"
        }
    }

    private var learnSectionVocabularyChoiceLabel: String {
        if appLanguage == .ukrainian {
            return "Слова розділу"
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Abschnitt-Wörter"
        case .turkish:
            return "Bölüm kelimeleri"
        case .english:
            return "Section words"
        }
    }

    private func materialLearningChoiceMessage(fileName: String, mode: ConversationMode?) -> String {
        let sectionInfo = mode.map { activeSectionStatusText(for: $0) } ?? ""
        if appLanguage == .ukrainian {
            return "Файл завантажено: \(fileName). \(sectionInfo) Хочете вчити слова, речення чи слова цього розділу?"
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Datei geladen: \(fileName). \(sectionInfo) Möchtest du Vokabeln, Sätze oder Abschnitt-Wörter lernen?"
        case .turkish:
            return "Dosya yüklendi: \(fileName). \(sectionInfo) Bu dosyadan kelime, cümle veya bölüm kelimeleri çalışmak ister misin?"
        case .english:
            return "File loaded: \(fileName). \(sectionInfo) Do you want to learn vocabulary, sentences, or section words from this file?"
        }
    }

    private var materialModeSelectionRequiredStatus: String {
        if appLanguage == .ukrainian {
            return "Спочатку виберіть режим: слова, речення або слова розділу."
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Bitte zuerst Lernmodus wählen: Vokabeln, Sätze oder Abschnitt-Wörter."
        case .turkish:
            return "Lütfen önce öğrenme modunu seç: Kelime, cümle veya bölüm kelimeleri."
        case .english:
            return "Please choose learning mode first: Vocabulary, sentences, or section words."
        }
    }

    private func materialLoadedStatus(fileName: String, mode: ConversationMode) -> String {
        let languageName = mode.displayName(for: appLanguage)
        let sectionInfo = activeSectionStatusText(for: mode)
        if appLanguage == .ukrainian {
            return "Матеріал для \(languageName) завантажено: \(fileName). \(sectionInfo) Виберіть режим навчання."
        }
        switch appLanguage.localizationFamily {
        case .german:
            return "Material für \(languageName) geladen: \(fileName). \(sectionInfo) Lernmodus auswählen."
        case .turkish:
            return "\(languageName) için materyal yüklendi: \(fileName). \(sectionInfo) Öğrenme modunu seç."
        case .english:
            return "Material for \(languageName) loaded: \(fileName). \(sectionInfo) Choose learning mode."
        }
    }

    private func materialModeActivatedStatus(_ learningMode: MaterialLearningMode, mode: ConversationMode) -> String {
        let languageName = mode.displayName(for: appLanguage)
        let modeLabel: String
        switch learningMode {
        case .vocabulary:
            modeLabel = learnVocabularyChoiceLabel
        case .sentences:
            modeLabel = learnSentencesChoiceLabel
        case .sectionVocabulary:
            modeLabel = learnSectionVocabularyChoiceLabel
        }
        let sectionInfo = activeSectionStatusText(for: mode)
        if appLanguage == .ukrainian {
            if learningMode == .sectionVocabulary {
                return "Для \(languageName) увімкнено режим матеріалу: \(modeLabel). \(sectionInfo) Я зараз навчаю вас словам саме з цього розділу."
            }
            return "Для \(languageName) увімкнено режим матеріалу: \(modeLabel). \(sectionInfo)"
        }
        switch appLanguage.localizationFamily {
        case .german:
            if learningMode == .sectionVocabulary {
                return "Materialmodus für \(languageName) aktiv: \(modeLabel). \(sectionInfo) Ich bringe dir jetzt Wörter genau aus diesem Abschnitt bei."
            }
            return "Materialmodus für \(languageName) aktiv: \(modeLabel). \(sectionInfo)"
        case .turkish:
            if learningMode == .sectionVocabulary {
                return "\(languageName) için materyal modu etkin: \(modeLabel). \(sectionInfo) Şimdi sana tam bu bölümden kelimeler öğreteceğim."
            }
            return "\(languageName) için materyal modu etkin: \(modeLabel). \(sectionInfo)"
        case .english:
            if learningMode == .sectionVocabulary {
                return "Material mode active for \(languageName): \(modeLabel). \(sectionInfo) I will now teach you words specifically from this section."
            }
            return "Material mode active for \(languageName): \(modeLabel). \(sectionInfo)"
        }
    }

    private var selectedConversationTopic: ConversationTopic {
        ConversationTopic.fromStoredValue(storedConversationTopic)
    }

    private var hasManualTopic: Bool {
        selectedConversationTopic != .automatic
    }

    private func speechVoiceTitle(_ voice: AVSpeechSynthesisVoice) -> String {
        "\(voice.name) (\(voice.language))"
    }

    private func sampleSpeechText(for mode: ConversationMode) -> String {
        switch mode {
        case .russian:
            return "Привет! Давай говорить медленно."
        case .turkish:
            return "Merhaba! Yavas ve net konusalim."
        case .english:
            return "Hello! Let's speak slowly and clearly."
        case .ukrainian:
            return "Привіт! Давай говорити повільно."
        case .italian:
            return "Ciao! Parliamo lentamente e chiaramente."
        case .spanish:
            return "Hola, hablemos despacio y claro."
        case .german:
            return "Hallo! Lass uns langsam und klar sprechen."
        }
    }

    private let speechRatePresets: [Double] = [0.34, 0.40, 0.46, 0.52, 0.58]

    private var speechRateLabel: String {
        String(format: "%.2f", storedSpeechRate)
    }

    private func speakTutorText(_ text: String) {
        speechOutput.speak(
            text,
            mode: conversationMode,
            rate: speechRate,
            preferredVoiceIdentifier: selectedSpeechVoiceIdentifier
        )
    }

    private func replayTutorText(_ text: String) {
        speechOutput.speak(
            text,
            mode: conversationMode,
            rate: speechRate,
            preferredVoiceIdentifier: selectedSpeechVoiceIdentifier,
            force: true
        )
    }

    private func translateTutorBubble(_ text: String, messageID: UUID, forceRefresh: Bool = false) {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return }

        if !forceRefresh, translatedTutorBubbleMessageID == messageID {
            translationRequestNonce += 1
            withAnimation(.easeInOut(duration: 0.2)) {
                translatingTutorBubbleMessageID = nil
                translatedTutorBubbleMessageID = nil
                translatedTutorBubbleText = ""
            }
            return
        }

        translationRequestNonce += 1
        let requestNonce = translationRequestNonce
        let targetLanguage = appLanguage
        translatingTutorBubbleMessageID = messageID
        requestScrollToBottomIfNeeded(for: messageID)
        Task { @MainActor in
            do {
                let prompt = """
                You are a translation engine.
                Translate the following text strictly into \(targetLanguage.translationTargetLanguageName).
                Output only the translated text in \(targetLanguage.translationTargetLanguageName), without explanation, label, or quotes.
                If the text is already in \(targetLanguage.translationTargetLanguageName), return it unchanged.
                Text:
                \(source)
                """
                let raw = try await generateResponse(for: prompt)
                guard requestNonce == translationRequestNonce else { return }
                let translated = normalizeTranslationMessage(raw, targetLanguage: targetLanguage)
                guard !translated.isEmpty else { return }
                guard requestNonce == translationRequestNonce else { return }
                guard translatingTutorBubbleMessageID == messageID else { return }

                withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) {
                    translatedTutorBubbleMessageID = messageID
                    translatedTutorBubbleText = translated
                }
                requestScrollToBottomIfNeeded(for: messageID)
            } catch {
                guard requestNonce == translationRequestNonce else { return }
                contextStatusByMode[conversationMode] = "\(targetLanguage.translationErrorPrefix) \(error.localizedDescription)"
            }
            if requestNonce == translationRequestNonce, translatingTutorBubbleMessageID == messageID {
                translatingTutorBubbleMessageID = nil
            }
        }
    }

    private func normalizeTranslationMessage(_ text: String, targetLanguage: AppLanguage) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(
                of: "(?i)^(translation|uebersetzung|übersetzung|ceviri|çeviri)\\s*:\\s*",
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return "" }

        let enforced: String
        switch targetLanguage {
        case .german:
            enforced = extractGermanConversationText(from: cleaned) ?? cleaned
        case .turkish:
            enforced = extractTurkishConversationText(from: cleaned) ?? cleaned
        case .english:
            enforced = extractEnglishConversationText(from: cleaned) ?? cleaned
        case .ukrainian:
            enforced = extractUkrainianConversationText(from: cleaned) ?? cleaned
        case .spanish:
            enforced = extractSpanishConversationText(from: cleaned) ?? cleaned
        case .russian:
            enforced = extractRussianConversationText(from: cleaned) ?? cleaned
        }

        let final = enforced.trimmingCharacters(in: .whitespacesAndNewlines)
        if final.count <= 260 { return final }
        return String(final.prefix(260)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func refreshTranslatedBubbleForCurrentAppLanguage() {
        let bubbleID = translatedTutorBubbleMessageID ?? translatingTutorBubbleMessageID
        guard let bubbleID else { return }
        guard let message = messages.first(where: { $0.id == bubbleID && !$0.isUser }) else { return }
        translateTutorBubble(message.text, messageID: bubbleID, forceRefresh: true)
    }

    private func restartConversationAndSendOpening() {
        resetConversationForModeChange()
        if hasImportedContext && selectedMaterialLearningMode == nil {
            requestMaterialLearningModeSelection(for: conversationMode, fileName: importedContextName)
            return
        }
        sendOpeningPromptIfPossible()
    }

    private func beginDocumentImportForCurrentLanguage() {
        importTargetMode = conversationMode
        showDocumentImporter = true
    }

    private func requestMaterialLearningModeSelection(for mode: ConversationMode, fileName: String) {
        pendingMaterialLearningModeTarget = mode
        pendingMaterialLearningFileName = fileName
        showMaterialLearningModeDialog = true
    }

    private func applyMaterialLearningMode(_ learningMode: MaterialLearningMode, for mode: ConversationMode) {
        importedLearningModeByMode[mode] = learningMode
        contextStatusByMode[mode] = materialModeActivatedStatus(learningMode, mode: mode)
        pendingMaterialLearningModeTarget = nil
        pendingMaterialLearningFileName = ""
        if mode == conversationMode {
            restartConversationAndSendOpening()
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTopColor, backgroundBottomColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isKeyboardVisible: Bool {
        isInputFocused
    }

    private func audioDotOpacity(_ index: Int) -> Double {
        index < speechDotCount ? 1.0 : 0.25
    }

    private func waveformBarHeight(at index: Int) -> CGFloat {
        let activeLevel = speechManager.isRecording ? max(0.08, speechManager.audioLevel) : 0.16
        let phase = Double(waveformPhase + index * 2) * 0.6
        let oscillation = (sin(phase) + 1) * 0.5
        let base = CGFloat(8 + (index % 2) * 2)
        let boost = CGFloat(activeLevel) * 28
        return base + CGFloat(oscillation) * boost
    }

    private var translatedBubbleBackgroundColor: Color {
        let fallback = ContentView.defaultTutorBubbleColor
        let source = PersistedColor.from(tutorBubbleColor, fallback: fallback)
        let lightened = PersistedColor(
            red: (source.red * 0.45 + 0.55).clamped(to: 0...1),
            green: (source.green * 0.45 + 0.55).clamped(to: 0...1),
            blue: (source.blue * 0.45 + 0.55).clamped(to: 0...1),
            alpha: max(source.alpha, 0.96).clamped(to: 0...1)
        )
        return lightened.color
    }

    private func requestScrollToBottomIfNeeded(for messageID: UUID) {
        guard messages.last?.id == messageID else { return }
        scrollToBottomSignal += 1
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.26)) {
                    proxy.scrollTo(chatBottomID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(chatBottomID, anchor: .bottom)
            }
        }
    }

    private var feedbackHintTextColor: Color {
        let fallback = ContentView.defaultUserBubbleColor
        let source = PersistedColor.from(userBubbleColor, fallback: fallback)
        let darkened = PersistedColor(
            red: (source.red * 0.34).clamped(to: 0...1),
            green: (source.green * 0.34).clamped(to: 0...1),
            blue: (source.blue * 0.34).clamped(to: 0...1),
            alpha: 1.0
        )
        return darkened.color
    }

    private func toggleFeedbackDetails(for messageID: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedFeedbackMessageID == messageID {
                expandedFeedbackMessageID = nil
            } else {
                expandedFeedbackMessageID = messageID
            }
        }
    }

    private func applyFeedback(_ feedback: UserSentenceFeedback, toUserMessage userMessageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == userMessageID && $0.isUser }) else { return }
        messages[index].feedback = feedback
    }

    @ViewBuilder
    private func roundAudioControlButton(
        systemName: String,
        tint: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.92))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func messageRow(for msg: Message) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 44) }
            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 6) {
                Text(msg.text)
                    .padding(12)
                    .background(msg.isUser ? userBubbleColor : tutorBubbleColor)
                    .foregroundColor(msg.isUser ? .white : Color(red: 0.12, green: 0.18, blue: 0.25))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(msg.isUser ? Color.clear : Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if msg.isUser, let feedback = msg.feedback {
                            Button {
                                toggleFeedbackDetails(for: msg.id)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(feedback.iconBackgroundColor)
                                        .frame(width: 23, height: 23)
                                    Image(systemName: feedback.iconSystemName)
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(feedback.iconForegroundColor)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .offset(x: 8, y: 8)
                            .accessibilityLabel(appLanguage.correctionAccessibilityLabel)
                        }
                    }
                    .onTapGesture(count: 2) {
                        showBubbleColorSheet = true
                    }
                    .onTapGesture {
                        if !msg.isUser {
                            translateTutorBubble(msg.text, messageID: msg.id)
                        }
                    }

                if !msg.isUser, translatingTutorBubbleMessageID == msg.id {
                    Text("\(appLanguage.translationResultPrefix) \(appLanguage.processingLabel)…")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(translatedBubbleBackgroundColor)
                        .foregroundColor(Color(red: 0.24, green: 0.33, blue: 0.48))
                        .cornerRadius(13)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                        )
                        .padding(.top, -8)
                        .padding(.leading, 14)
                }

                if !msg.isUser,
                   translatedTutorBubbleMessageID == msg.id,
                   !translatedTutorBubbleText.isEmpty {
                    Text(translatedTutorBubbleText)
                        .font(.callout)
                        .padding(12)
                        .background(translatedBubbleBackgroundColor)
                        .foregroundColor(Color(red: 0.12, green: 0.19, blue: 0.30))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                        )
                        .padding(.top, -10)
                        .padding(.leading, 14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !msg.isUser {
                    let isActivePlayback = speechOutput.isPlaybackActive(for: msg.text)
                    let canPause = isActivePlayback && speechOutput.isSpeaking && !speechOutput.isPaused
                    let canResume = isActivePlayback && speechOutput.isPaused

                    HStack(spacing: 8) {
                        roundAudioControlButton(
                            systemName: canPause ? "pause.circle.fill" : "play.circle.fill",
                            tint: canPause ? Color(red: 0.85, green: 0.28, blue: 0.28) : Color(red: 0.16, green: 0.67, blue: 0.34),
                            accessibilityLabel: canPause ? appLanguage.pauseLabel : (canResume ? appLanguage.resumeLabel : appLanguage.replayLabel)
                        ) {
                            if canPause {
                                speechOutput.pause()
                            } else if canResume {
                                speechOutput.resume()
                            } else {
                                replayTutorText(msg.text)
                            }
                        }

                        roundAudioControlButton(
                            systemName: "arrow.counterclockwise.circle.fill",
                            tint: Color(red: 0.08, green: 0.45, blue: 0.75),
                            accessibilityLabel: appLanguage.replayFromStartLabel
                        ) {
                            replayTutorText(msg.text)
                        }

                        Menu {
                            ForEach(speechRatePresets, id: \.self) { rate in
                                Button {
                                    storedSpeechRate = rate
                                    replayTutorText(msg.text)
                                } label: {
                                    if abs(storedSpeechRate - rate) < 0.001 {
                                        Label("\(appLanguage.speedLabelWord) \(rate, specifier: "%.2f")", systemImage: "checkmark")
                                    } else {
                                        Text("\(appLanguage.speedLabelWord) \(rate, specifier: "%.2f")")
                                    }
                                }
                            }
                        } label: {
                            Label("\(appLanguage.speedLabelWord) \(speechRateLabel)", systemImage: "speedometer")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.92))
                                .foregroundColor(Color(red: 0.28, green: 0.36, blue: 0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                                )
                        }

                        Menu {
                            Button {
                                selectedSpeechVoiceBinding.wrappedValue = ""
                                replayTutorText(msg.text)
                            } label: {
                                if selectedSpeechVoiceIdentifier.isEmpty {
                                    Label(appLanguage.defaultVoiceLabel, systemImage: "checkmark")
                                } else {
                                    Text(appLanguage.defaultVoiceLabel)
                                }
                            }
                            ForEach(availableSpeechVoicesForMode, id: \.identifier) { voice in
                                Button {
                                    selectedSpeechVoiceBinding.wrappedValue = voice.identifier
                                    replayTutorText(msg.text)
                                } label: {
                                    if selectedSpeechVoiceIdentifier == voice.identifier {
                                        Label(speechVoiceTitle(voice), systemImage: "checkmark")
                                    } else {
                                        Text(speechVoiceTitle(voice))
                                    }
                                }
                            }
                        } label: {
                            Label(appLanguage.voicePickerTitle, systemImage: "waveform.circle")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.92))
                                .foregroundColor(Color(red: 0.28, green: 0.36, blue: 0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                                )
                        }
                    }
                }

                if msg.isUser,
                   let feedback = msg.feedback,
                   expandedFeedbackMessageID == msg.id {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appLanguage.feedbackTitle(for: feedback.level))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(feedbackHintTextColor)
                        if feedback.level == .good {
                            if let alternative = feedback.alternative, !alternative.isEmpty {
                                Text("\(appLanguage.alternativePrefix) \(alternative)")
                                    .font(.callout)
                                    .foregroundColor(feedbackHintTextColor)
                            }
                        } else {
                            Text(feedback.correction)
                                .font(.callout)
                                .foregroundColor(feedbackHintTextColor)
                        }
                        HStack(spacing: 8) {
                            Button {
                                let textToSpeak = feedback.level == .good ? msg.text : feedback.correction
                                speakTutorText(textToSpeak)
                            } label: {
                                Label(appLanguage.listenLabel, systemImage: "speaker.wave.2.fill")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.08, green: 0.45, blue: 0.75))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            if feedback.level == .good,
                               let alternative = feedback.alternative,
                               !alternative.isEmpty {
                                Button {
                                    speakTutorText(alternative)
                                } label: {
                                    Label(appLanguage.alternativeLabel, systemImage: "text.bubble")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.92))
                                        .foregroundColor(Color(red: 0.08, green: 0.45, blue: 0.75))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Button(appLanguage.closeLabel) {
                                toggleFeedbackDetails(for: msg.id)
                            }
                            .font(.caption)
                            .foregroundColor(feedbackHintTextColor)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.985))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(red: 0.73, green: 0.83, blue: 0.92), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxWidth: 280, alignment: .leading)
                }
            }
            if !msg.isUser { Spacer(minLength: 44) }
        }
        .id(msg.id)
    }

    private var documentImportControl: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                beginDocumentImportForCurrentLanguage()
            } label: {
                Image(systemName: hasImportedContext ? "doc.text.fill" : "doc.badge.plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(isDocumentDropTargeted ? Color.white.opacity(0.45) : Color.white.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                isDocumentDropTargeted ? Color(red: 0.06, green: 0.53, blue: 0.45) : Color.white.opacity(0.45),
                                lineWidth: isDocumentDropTargeted ? 2 : 1
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("PDF oder TXT fuer \(conversationLanguageName) laden")

            if hasImportedContext {
                Button {
                    clearImportedContext()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color(red: 0.86, green: 0.25, blue: 0.25))
                        )
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .accessibilityLabel("Material fuer \(conversationLanguageName) entfernen")
            }
        }
        .frame(width: 46, height: 46)
        .dropDestination(
            for: URL.self,
            action: { items, _ in
                handleDroppedDocuments(items)
            },
            isTargeted: { targeted in
                isDocumentDropTargeted = targeted
            }
        )
    }

    private var languageCornerStripMenu: some View {
        Menu {
            ForEach(ConversationMode.allCases) { mode in
                Button {
                    storedConversationMode = mode.rawValue
                } label: {
                    if mode == conversationMode {
                        Label("\(flag(for: mode)) \(mode.displayName(for: appLanguage))", systemImage: "checkmark")
                    } else {
                        Text("\(flag(for: mode)) \(mode.displayName(for: appLanguage))")
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(conversationFlag)
                    .font(.title3)
                Text(code(for: conversationMode))
                    .font(.caption.weight(.bold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(Color(red: 0.08, green: 0.18, blue: 0.30))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.34))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.70), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(appLanguage.learningLanguagePickerAccessibilityLabel). Aktuell: \(conversationLanguageName)")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundGradient
                .ignoresSafeArea()
                .onTapGesture(count: 2) {
                    showBackgroundColorSheet = true
                }

            VStack {
                HStack {
                    Spacer()
                        .frame(width: 112)

                    documentImportControl

                    Menu {
                        ForEach(LanguageLevel.allCases) { level in
                            Button {
                                storedLanguageLevel = level.rawValue
                            } label: {
                                if level == languageLevel {
                                    Label(level.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(level.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(languageLevel.rawValue)
                                .font(.caption.weight(.bold))
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(appLanguage.levelPickerAccessibilityLabel). Aktuell: \(languageLevel.rawValue)")

                    Spacer()

                    Menu {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                storedAppLanguage = language.rawValue
                            } label: {
                                if language == appLanguage {
                                    Label("\(language.flag) \(language.rawValue)", systemImage: "checkmark")
                                } else {
                                    Text("\(language.flag) \(language.rawValue)")
                                }
                            }
                        }
                    } label: {
                        Text(appLanguage.flag)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(appLanguage.appLanguagePickerAccessibilityLabel). Aktuell: \(appLanguage.rawValue)")

                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .padding(10)
                            .background(Color.white.opacity(0.28))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if !contextStatusMessage.isEmpty {
                    Text(contextStatusMessage)
                        .font(.caption2)
                        .foregroundColor(contextStatusMessage.hasPrefix("Fehler") ? .red : Color(red: 0.16, green: 0.3, blue: 0.48))
                        .padding(.horizontal)
                        .padding(.top, 2)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                messageRow(for: msg)
                            }
                            if speechManager.isRecording || isAwaitingSpeechResult {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Image(systemName: speechManager.isRecording ? "waveform" : "hourglass")
                                            .font(.caption.bold())
                                        HStack(spacing: 4) {
                                            ForEach(0..<3, id: \.self) { index in
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 6, height: 6)
                                                    .opacity(audioDotOpacity(index))
                                            }
                                        }
                                        Text(speechManager.isRecording ? appLanguage.speechInputLabel : appLanguage.processingLabel)
                                            .font(.caption2.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [userBubbleColor.opacity(0.98), userBubbleColor.opacity(0.82)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                }
                            }
                            Color.clear
                                .frame(height: 1)
                                .id(chatBottomID)
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(Color.white.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal)
                    .onAppear {
                        scrollToBottom(using: proxy, animated: false)
                    }
                    .onChange(of: messages.count) {
                        scrollToBottom(using: proxy)
                    }
                    .onChange(of: scrollToBottomSignal) {
                        scrollToBottom(using: proxy)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                VStack(spacing: 0) {
                    HStack {
                        TextField(
                            appLanguage.inputPlaceholder,
                            text: $typedText,
                            prompt: Text(appLanguage.inputPlaceholder).foregroundColor(Color(red: 0.5, green: 0.57, blue: 0.66))
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.95))
                        .foregroundColor(Color(red: 0.08, green: 0.14, blue: 0.24))
                        .tint(Color(red: 0.08, green: 0.45, blue: 0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isInputFocused)
                        .onSubmit {
                            if sendIfPossible(typedText) {
                                typedText = ""
                            }
                        }

                        Button(appLanguage.sendLabel) {
                            if sendIfPossible(typedText) {
                                typedText = ""
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.08, green: 0.45, blue: 0.75))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)

                    if aiProvider == .gemini && effectiveGeminiApiKey.isEmpty {
                        Text(appLanguage.geminiKeyMissingLabel)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    if aiProvider == .groq && groqApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(appLanguage.groqKeyMissingLabel)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if !speechManager.errorMessage.isEmpty {
                        Text(speechManager.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }

                    if !isKeyboardVisible {
                        VStack {
                            Text(speechManager.isRecording ? appLanguage.listeningNowLabel : appLanguage.holdToSpeakLabel)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            if speechManager.isRecording || isAwaitingSpeechResult {
                                HStack(alignment: .center, spacing: 4) {
                                    ForEach(0..<7, id: \.self) { index in
                                        Capsule()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 4, height: waveformBarHeight(at: index))
                                    }
                                }
                                .frame(height: 34)
                                .padding(.vertical, 2)
                            }

                            Circle()
                                .fill(speechManager.isRecording ? Color(red: 0.87, green: 0.23, blue: 0.27) : Color(red: 0.08, green: 0.45, blue: 0.75))
                                .frame(width: 74, height: 74)
                                .overlay(Image(systemName: "mic.fill").foregroundColor(.white).font(.title2))
                                .scaleEffect(speechManager.isRecording ? 1.2 : 1.0)
                                .animation(.spring(), value: speechManager.isRecording)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !speechManager.isRecording {
                                                isAwaitingSpeechResult = false
                                                speechDotCount = 1
                                                speechManager.start(
                                                    for: conversationMode,
                                                    includeGermanFallback: false
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            speechManager.stop()
                                            isAwaitingSpeechResult = true
                                            speechDotCount = 1
                                            Task { @MainActor in
                                                let spoken = await speechManager.consumeBestTranscriptAfterStop(for: conversationMode)
                                                isAwaitingSpeechResult = false
                                                let trimmed = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if trimmed.isEmpty {
                                                    speechManager.errorMessage = appLanguage.speechNotDetectedLabel
                                                    return
                                                }
                                                _ = sendIfPossible(trimmed)
                                            }
                                        }
                                )
                        }
                        .padding(.vertical, 20)
                    } else {
                        Text(appLanguage.enterSendHintLabel)
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.45))
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: isInputFocused)
            }

            languageCornerStripMenu
                .padding(.top, 8)
                .padding(.leading, 8)
        }
        .onAppear {
            guard !hasStartedConversation else { return }
            hasStartedConversation = true
            if storedConversationMode != conversationMode.rawValue {
                storedConversationMode = conversationMode.rawValue
            }
            if storedAppLanguage != appLanguage.rawValue {
                storedAppLanguage = appLanguage.rawValue
            }
            sanitizeSelectedVoiceForCurrentMode()
            loadStoredColors()
            geminiApiKeyInput = KeychainStore.load(account: geminiKeychainAccount)
            groqApiKeyInput = KeychainStore.load(account: groqKeychainAccount)
            storedConversationTopic = selectedConversationTopic.rawValue
        }
        .onReceive(speechAnimationTimer) { _ in
            guard speechManager.isRecording || isAwaitingSpeechResult else { return }
            speechDotCount = (speechDotCount % 3) + 1
            waveformPhase = (waveformPhase + 1) % 10_000
        }
        .onChange(of: geminiApiKeyInput) { _, newValue in
            KeychainStore.save(value: newValue, for: geminiKeychainAccount)
        }
        .onChange(of: groqApiKeyInput) { _, newValue in
            KeychainStore.save(value: newValue, for: groqKeychainAccount)
        }
        .onChange(of: storedConversationMode) {
            sanitizeSelectedVoiceForCurrentMode()
            restartConversationAndSendOpening()
        }
        .onChange(of: storedAppLanguage) {
            translationRequestNonce += 1
            refreshTranslatedBubbleForCurrentAppLanguage()
        }
        .onChange(of: storedConversationTopic) {
            resetConversationForModeChange()
        }
        .onChange(of: storedAIProvider) {
            resetConversationForModeChange()
        }
        .confirmationDialog(
            materialLearningChoiceTitle,
            isPresented: $showMaterialLearningModeDialog,
            titleVisibility: .visible
        ) {
            Button(learnVocabularyChoiceLabel) {
                guard let mode = pendingMaterialLearningModeTarget else { return }
                applyMaterialLearningMode(.vocabulary, for: mode)
            }
            Button(learnSentencesChoiceLabel) {
                guard let mode = pendingMaterialLearningModeTarget else { return }
                applyMaterialLearningMode(.sentences, for: mode)
            }
            Button(learnSectionVocabularyChoiceLabel) {
                guard let mode = pendingMaterialLearningModeTarget else { return }
                applyMaterialLearningMode(.sectionVocabulary, for: mode)
            }
            Button(appLanguage.closeLabel, role: .cancel) {}
        } message: {
            Text(materialLearningChoiceMessage(fileName: pendingMaterialLearningFileName, mode: pendingMaterialLearningModeTarget))
        }
        .sheet(isPresented: $showBackgroundColorSheet) {
            NavigationStack {
                Form {
                    Section(appLanguage.backgroundSectionTitle) {
                        ColorPicker(appLanguage.topColorLabel, selection: backgroundTopColorBinding, supportsOpacity: false)
                        ColorPicker(appLanguage.bottomColorLabel, selection: backgroundBottomColorBinding, supportsOpacity: false)
                    }
                    Button(appLanguage.defaultColorsButtonTitle) {
                        resetColorsToDefault()
                    }
                }
                .navigationTitle(appLanguage.backgroundColorTitle)
            }
        }
        .sheet(isPresented: $showBubbleColorSheet) {
            NavigationStack {
                Form {
                    Section(appLanguage.bubbleSectionTitle) {
                        ColorPicker(appLanguage.meBubbleLabel, selection: userBubbleColorBinding, supportsOpacity: false)
                        ColorPicker(appLanguage.trainerBubbleLabel, selection: tutorBubbleColorBinding, supportsOpacity: false)
                    }
                    Button(appLanguage.defaultColorsButtonTitle) {
                        resetColorsToDefault()
                    }
                }
                .navigationTitle(appLanguage.bubbleColorTitle)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            settingsSheetView
                .id("settings-\(storedAppLanguage)")
        }
        .fileImporter(
            isPresented: $showDocumentImporter,
            allowedContentTypes: [.pdf, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
    }

    private var settingsSheetView: some View {
        NavigationStack {
            Form {
                Section(appLanguage.modelSectionTitle) {
                    Picker(appLanguage.providerPickerTitle, selection: $storedAIProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName(for: appLanguage)).tag(provider.rawValue)
                        }
                    }

                    if aiProvider == .groq {
                        SecureField(appLanguage.groqApiKeyFieldTitle, text: $groqApiKeyInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Picker(appLanguage.groqSuggestionPickerTitle, selection: $storedGroqModel) {
                            ForEach(groqModelSuggestions, id: \.self) { model in
                                Text(model)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .tag(model)
                            }
                            if !groqModelSuggestions.contains(storedGroqModel) {
                                Text("\(appLanguage.customPrefix) \(storedGroqModel)")
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .tag(storedGroqModel)
                            }
                        }
                        Text("\(appLanguage.currentPrefix) \(storedGroqModel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        TextField(appLanguage.groqCustomModelFieldTitle, text: $storedGroqModel)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Text(appLanguage.groqModelHint)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if aiProvider == .ollama {
                        TextField(appLanguage.ollamaURLFieldTitle, text: $storedOllamaBaseURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Picker(appLanguage.ollamaSuggestionPickerTitle, selection: $storedOllamaModel) {
                            ForEach(ollamaModelSuggestions, id: \.self) { model in
                                Text(model)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .tag(model)
                            }
                            if !ollamaModelSuggestions.contains(storedOllamaModel) {
                                Text("\(appLanguage.customPrefix) \(storedOllamaModel)")
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .tag(storedOllamaModel)
                            }
                        }
                        Text("\(appLanguage.currentPrefix) \(storedOllamaModel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        TextField(appLanguage.ollamaCustomModelFieldTitle, text: $storedOllamaModel)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Text(appLanguage.ollamaSimulatorHint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        SecureField(appLanguage.geminiApiKeyFieldTitle, text: $geminiApiKeyInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Picker(appLanguage.geminiModelPickerTitle, selection: $storedGeminiModelPreset) {
                            Text(appLanguage.automaticLabel)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .tag(automaticGeminiModel)
                            ForEach(geminiModelSuggestions, id: \.self) { model in
                                Text(model)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .tag(model)
                            }
                        }
                        Text("\(appLanguage.currentPrefix) \(storedGeminiModelPreset == automaticGeminiModel ? appLanguage.automaticLabel : storedGeminiModelPreset)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        TextField(appLanguage.geminiCustomModelFieldTitle, text: $storedGeminiCustomModel)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Text(appLanguage.geminiCustomModelHint)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                }

                Section(appLanguage.samplingSectionTitle) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(appLanguage.tempLabel): \(modelTemperature, specifier: "%.2f")")
                        Slider(value: modelTemperatureBinding, in: 0.0...2.0, step: 0.01)
                    }
                    Text(appLanguage.tempHint)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Section(appLanguage.conversationSectionTitle) {
                    Picker(appLanguage.conversationLanguagePickerTitle, selection: $storedConversationMode) {
                        ForEach(ConversationMode.allCases) { mode in
                            Text(mode.displayName(for: appLanguage)).tag(mode.rawValue)
                        }
                    }

                    Picker(appLanguage.topicPickerTitle, selection: $storedConversationTopic) {
                        ForEach(ConversationTopic.allCases) { topic in
                            Text(topic.displayName(for: appLanguage)).tag(topic.rawValue)
                        }
                    }

                    Picker(appLanguage.responseLengthPickerTitle, selection: $storedResponseLengthMode) {
                        ForEach(TutorResponseLength.allCases) { option in
                            Text(option.title(for: appLanguage)).tag(option.rawValue)
                        }
                    }
                    Text(appLanguage.responseLengthHint)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Section(appLanguage.hintsSectionTitle) {
                    Picker(appLanguage.appLanguagePickerTitle, selection: $storedAppLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.rawValue).tag(language.rawValue)
                        }
                    }
                    Text(appLanguage.settingsHintText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Section(appLanguage.audioSectionTitle) {
                    Toggle(appLanguage.readAnswerToggleTitle, isOn: $speechOutput.isEnabled)
                    Text(appLanguage.readAnswerHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(appLanguage.speechTempoLabel): \(storedSpeechRate, specifier: "%.2f")")
                        Slider(value: $storedSpeechRate, in: 0.32...0.60, step: 0.01)
                    }
                    Picker(appLanguage.voicePickerTitle, selection: selectedSpeechVoiceBinding) {
                        Text(appLanguage.defaultVoiceLabel).tag("")
                        ForEach(availableSpeechVoicesForMode, id: \.identifier) { voice in
                            Text(speechVoiceTitle(voice)).tag(voice.identifier)
                        }
                    }
                    if !selectedSpeechVoiceIdentifier.isEmpty &&
                        !availableSpeechVoicesForMode.contains(where: { $0.identifier == selectedSpeechVoiceIdentifier }) {
                        Text(appLanguage.voiceUnavailableHint)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Button(appLanguage.testVoiceButtonTitle) {
                        speakTutorText(sampleSpeechText(for: conversationMode))
                    }
                }

            }
            .navigationTitle(appLanguage.settingsTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                storedAppLanguage = language.rawValue
                            } label: {
                                if language == appLanguage {
                                    Label("\(language.flag) \(language.rawValue)", systemImage: "checkmark")
                                } else {
                                    Text("\(language.flag) \(language.rawValue)")
                                }
                            }
                        }
                    } label: {
                        Text(appLanguage.flag)
                    }
                    .accessibilityLabel("\(appLanguage.settingsLanguageMenuLabel). Aktuell: \(appLanguage.rawValue)")
                }
            }
        }
    }

    private func sendIfPossible(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if hasImportedContext && selectedMaterialLearningMode == nil {
            contextStatusByMode[conversationMode] = materialModeSelectionRequiredStatus
            requestMaterialLearningModeSelection(for: conversationMode, fileName: importedContextName)
            return false
        }
        if isSending {
            queuedUserInputs.append(trimmed)
            return true
        }
        sendToGemini(trimmed)
        return true
    }

    private func flushQueuedInputIfPossible() {
        guard !isSending, !queuedUserInputs.isEmpty else { return }
        let next = queuedUserInputs.removeFirst()
        sendToGemini(next)
    }

    private func resetConversationForModeChange() {
        activeRequestID = UUID()
        isSending = false
        queuedUserInputs.removeAll()
        typedText = ""
        expandedFeedbackMessageID = nil
        isInputFocused = false
        isAwaitingSpeechResult = false
        speechDotCount = 1
        waveformPhase = 0
        translatingTutorBubbleMessageID = nil
        translatedTutorBubbleMessageID = nil
        translatedTutorBubbleText = ""
        speechManager.stop()
        speechOutput.stop()
        messages = []
    }

    private func sendOpeningPromptIfPossible() {
        if aiProvider == .gemini && effectiveGeminiApiKey.isEmpty { return }
        if aiProvider == .groq && groqApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        guard messages.count <= 1 else { return }

        isSending = true
        let requestID = activeRequestID
        var openingPrompt = """
        Starte ein leichtes Gespraech (\(languageLevel.rawValue)) auf \(conversationLanguageName).
        Nutze nur \(conversationLanguageName), ohne Sprachmix.
        Gib genau eine kurze Einstiegsfrage auf \(conversationLanguageName), maximal 8 Woerter.
        Niveau-Regel: \(languageLevel.promptGuidance)
        """
        let topicContext = topicPromptBlock()
        if !topicContext.isEmpty {
            openingPrompt += """

            \(topicContext)
            """
        }
        let materialContext = materialContextPromptBlock(maxChars: 3500)
        if !materialContext.isEmpty {
            openingPrompt += """

            Der Dialog muss sich auf den folgenden Materialkontext beziehen:
            \(materialContext)
            """
        }

        Task {
            do {
                let opening = normalizeTutorMessage(
                    try await generateResponse(for: openingPrompt),
                    isExplanation: false,
                    mode: conversationMode
                )
                guard requestID == activeRequestID else { return }
                messages.append(Message(text: opening, isUser: false))
                speakTutorText(opening)
            } catch {
                guard requestID == activeRequestID else { return }
                messages.append(Message(text: "Modell-Fehler: \(error.localizedDescription)", isUser: false))
            }
            if requestID == activeRequestID {
                isSending = false
                flushQueuedInputIfPossible()
            }
        }
    }

    private func buildConversationContext(maxTurns: Int = 8) -> String {
        let conversation = messages.suffix(maxTurns).map { msg in
            let role = msg.isUser ? "Nutzer" : "Tutor"
            return "\(role): \(msg.text)"
        }
        return conversation.joined(separator: "\n")
    }

    private func materialContextPromptBlock(maxChars: Int = 6000) -> String {
        let trimmed = importedContextText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let limited = String(trimmed.prefix(maxChars))
        let activeSection = currentImportedContext?.sectionLabel ?? "1/1"
        let learningGuidance: String
        switch selectedMaterialLearningMode {
        case .vocabulary:
            learningGuidance = """
            Material-Lernmodus: Vokabeln.
            - Gehe den Inhalt Schritt fuer Schritt durch.
            - Nutze pro Antwort genau 1 wichtige Vokabel aus dem Material.
            - Stelle dazu eine kurze Uebung oder Rueckfrage.
            - Korrigiere kurz und geh dann zur naechsten Vokabel.
            """
        case .sentences:
            learningGuidance = """
            Material-Lernmodus: Saetze.
            - Gehe den Inhalt Schritt fuer Schritt durch.
            - Nutze pro Antwort genau 1 kurzen Satz aus dem Material.
            - Stelle dazu eine kurze Uebung (nachsprechen, umformulieren oder passend antworten).
            - Korrigiere kurz und geh dann zum naechsten Satz.
            """
        case .sectionVocabulary:
            learningGuidance = """
            Material-Lernmodus: Abschnitt-Woerter.
            - Aktiver Abschnitt: \(activeSection).
            - Sage am Anfang kurz, dass jetzt Woerter aus Abschnitt \(activeSection) gelernt werden.
            - Nutze pro Antwort 1 bis 2 zentrale Woerter nur aus diesem Abschnitt.
            - Erklaere kurz, lass den Nutzer aktiv wiederholen/verwenden und korrigiere knapp.
            """
        case .none:
            learningGuidance = """
            Material-Lernmodus noch nicht festgelegt.
            - Frage zuerst kurz: "Vokabeln, Saetze oder Abschnitt-Woerter aus dem Material?"
            """
        }
        return """
        Datei: \(importedContextName)
        Aktiver Abschnitt: \(activeSection)
        Kontextauszug:
        \(limited)

        Kontext-Regeln:
        - Beziehe normale Antworten inhaltlich auf diesen Kontext.
        - Nutze diesen Kontext statt einer allgemeinen Rubrik.
        - Wenn etwas nicht im Kontext steht, sage kurz "Nicht im Material" und bleib beim Kontext.
        \(learningGuidance)
        """
    }

    private func topicPromptBlock() -> String {
        guard !hasImportedContext else { return "" }
        guard hasManualTopic else { return "" }
        return """
        Aktive Rubrik: \(selectedConversationTopic.promptLabel)
        Rubrik-Regeln:
        - Fuehre die Unterhaltung hauptsaechlich in dieser Rubrik.
        - Bleibe bei dieser Rubrik, ausser der Nutzer wechselt klar das Thema.
        """
    }

    private func strictLanguageOnlyRule(for mode: ConversationMode) -> String {
        switch mode {
        case .turkish:
            return "- Nutze strikt nur Türkisch. Keine deutschen Woerter oder deutschen Saetze."
        case .german:
            return "- Nutze strikt nur Deutsch. Keine türkischen Woerter oder türkischen Saetze."
        default:
            return "- Nutze strikt nur \(conversationLanguageName)."
        }
    }

    private var backgroundTopColorBinding: Binding<Color> {
        Binding {
            backgroundTopColor
        } set: { newValue in
            backgroundTopColor = newValue
            storeCurrentColors()
        }
    }

    private var backgroundBottomColorBinding: Binding<Color> {
        Binding {
            backgroundBottomColor
        } set: { newValue in
            backgroundBottomColor = newValue
            storeCurrentColors()
        }
    }

    private var userBubbleColorBinding: Binding<Color> {
        Binding {
            userBubbleColor
        } set: { newValue in
            userBubbleColor = newValue
            storeCurrentColors()
        }
    }

    private var tutorBubbleColorBinding: Binding<Color> {
        Binding {
            tutorBubbleColor
        } set: { newValue in
            tutorBubbleColor = newValue
            storeCurrentColors()
        }
    }

    private func loadStoredColors() {
        backgroundTopColor = PersistedColor.decoded(
            from: storedBackgroundTopColor,
            fallback: ContentView.defaultBackgroundTopColor
        ).color
        backgroundBottomColor = PersistedColor.decoded(
            from: storedBackgroundBottomColor,
            fallback: ContentView.defaultBackgroundBottomColor
        ).color
        userBubbleColor = PersistedColor.decoded(
            from: storedUserBubbleColor,
            fallback: ContentView.defaultUserBubbleColor
        ).color
        tutorBubbleColor = PersistedColor.decoded(
            from: storedTutorBubbleColor,
            fallback: ContentView.defaultTutorBubbleColor
        ).color
    }

    private func storeCurrentColors() {
        storedBackgroundTopColor = PersistedColor.from(
            backgroundTopColor,
            fallback: ContentView.defaultBackgroundTopColor
        ).encoded
        storedBackgroundBottomColor = PersistedColor.from(
            backgroundBottomColor,
            fallback: ContentView.defaultBackgroundBottomColor
        ).encoded
        storedUserBubbleColor = PersistedColor.from(
            userBubbleColor,
            fallback: ContentView.defaultUserBubbleColor
        ).encoded
        storedTutorBubbleColor = PersistedColor.from(
            tutorBubbleColor,
            fallback: ContentView.defaultTutorBubbleColor
        ).encoded
    }

    private func resetColorsToDefault() {
        backgroundTopColor = ContentView.defaultBackgroundTopColor.color
        backgroundBottomColor = ContentView.defaultBackgroundBottomColor.color
        userBubbleColor = ContentView.defaultUserBubbleColor.color
        tutorBubbleColor = ContentView.defaultTutorBubbleColor.color
        storeCurrentColors()
    }

    private func clearImportedContext() {
        importedContextsByMode.removeValue(forKey: conversationMode)
        importedLearningModeByMode.removeValue(forKey: conversationMode)
        if pendingMaterialLearningModeTarget == conversationMode {
            pendingMaterialLearningModeTarget = nil
            pendingMaterialLearningFileName = ""
            showMaterialLearningModeDialog = false
        }
        contextStatusByMode[conversationMode] = "Material fuer \(conversationLanguageName) entfernt."
        resetConversationForModeChange()
    }

    private func handleDroppedDocuments(_ urls: [URL]) -> Bool {
        let targetMode = conversationMode
        guard let firstSupported = urls.first(where: { isSupportedImportFile($0) }) else {
            contextStatusByMode[targetMode] = "Fehler beim Einlesen: Bitte PDF oder TXT auf das Symbol ziehen."
            return false
        }
        importContextDocument(from: firstSupported, for: targetMode)
        return true
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        let targetMode = importTargetMode ?? conversationMode
        importTargetMode = nil
        switch result {
        case .success(let urls):
            guard let firstURL = urls.first else { return }
            importContextDocument(from: firstURL, for: targetMode)
        case .failure(let error):
            contextStatusByMode[targetMode] = "Fehler beim Oeffnen: \(error.localizedDescription)"
        }
    }

    private func importContextDocument(from url: URL, for mode: ConversationMode) {
        do {
            guard isSupportedImportFile(url) else {
                throw NSError(
                    domain: "DocumentImport",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Bitte eine PDF oder TXT-Datei auswaehlen."]
                )
            }

            let raw = try readImportedDocument(from: url)
            let normalized = normalizeImportedText(raw)
            guard !normalized.isEmpty else {
                throw NSError(
                    domain: "DocumentImport",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Die Datei enthaelt keinen lesbaren Text."]
                )
            }

            let limited = String(normalized.prefix(24_000))
            let sections = splitImportedTextIntoSections(limited, maxSectionCharacters: 1800)
            let selectedSectionText = sections.first ?? limited
            let totalSections = max(sections.count, 1)
            importedContextsByMode[mode] = ImportedContext(
                name: url.lastPathComponent,
                text: selectedSectionText,
                sectionIndex: 1,
                totalSections: totalSections
            )
            importedLearningModeByMode.removeValue(forKey: mode)
            contextStatusByMode[mode] = materialLoadedStatus(fileName: url.lastPathComponent, mode: mode)
            requestMaterialLearningModeSelection(for: mode, fileName: url.lastPathComponent)
            if mode == conversationMode {
                resetConversationForModeChange()
            }
        } catch {
            contextStatusByMode[mode] = "Fehler beim Einlesen: \(error.localizedDescription)"
        }
    }

    private func readImportedDocument(from url: URL) throws -> String {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if isPDFFile(url) {
            return try extractTextFromPDF(url)
        }
        return try extractTextFromTextFile(url)
    }

    private func isSupportedImportFile(_ url: URL) -> Bool {
        if isPDFFile(url) { return true }
        if isPlainTextFile(url) { return true }
        return false
    }

    private func isPDFFile(_ url: URL) -> Bool {
        if url.pathExtension.lowercased() == "pdf" { return true }
        let values = try? url.resourceValues(forKeys: [.contentTypeKey])
        if let contentType = values?.contentType {
            return contentType.conforms(to: .pdf)
        }
        return false
    }

    private func isPlainTextFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ["txt", "text", "md", "markdown", "csv", "log"].contains(ext) {
            return true
        }
        let values = try? url.resourceValues(forKeys: [.contentTypeKey])
        if let contentType = values?.contentType {
            return contentType.conforms(to: .plainText) || contentType.conforms(to: .text)
        }
        return false
    }

    private func extractTextFromPDF(_ url: URL) throws -> String {
        guard let pdf = PDFDocument(url: url) else {
            throw NSError(
                domain: "DocumentImport",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "PDF konnte nicht geoeffnet werden."]
            )
        }

        var combined = [String]()
        for pageIndex in 0..<pdf.pageCount {
            if let pageText = pdf.page(at: pageIndex)?.string, !pageText.isEmpty {
                combined.append(pageText)
            }
        }
        let joined = combined.joined(separator: "\n")
        if joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NSError(
                domain: "DocumentImport",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "PDF enthaelt keinen auslesbaren Text."]
            )
        }
        return joined
    }

    private func extractTextFromTextFile(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .windowsCP1252,
            .isoLatin1
        ]

        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return text
            }
        }

        throw NSError(
            domain: "DocumentImport",
            code: 6,
            userInfo: [NSLocalizedDescriptionKey: "TXT-Encoding wird nicht unterstuetzt."]
        )
    }

    private func normalizeImportedText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func splitImportedTextIntoSections(
        _ text: String,
        maxSectionCharacters: Int
    ) -> [String] {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map {
                $0
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        guard !paragraphs.isEmpty else { return [] }

        var sections: [String] = []
        var currentSection = ""

        func appendCurrentSectionIfNeeded() {
            let trimmed = currentSection.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                sections.append(trimmed)
            }
            currentSection = ""
        }

        for paragraph in paragraphs {
            if paragraph.count > maxSectionCharacters {
                appendCurrentSectionIfNeeded()

                let words = paragraph.split(whereSeparator: \.isWhitespace)
                var chunk = ""
                for word in words {
                    let wordText = String(word)
                    if chunk.isEmpty {
                        chunk = wordText
                        continue
                    }

                    if chunk.count + 1 + wordText.count > maxSectionCharacters {
                        sections.append(chunk)
                        chunk = wordText
                    } else {
                        chunk += " " + wordText
                    }
                }
                if !chunk.isEmpty {
                    sections.append(chunk)
                }
                continue
            }

            if currentSection.isEmpty {
                currentSection = paragraph
                continue
            }

            if currentSection.count + 2 + paragraph.count <= maxSectionCharacters {
                currentSection += "\n\n" + paragraph
            } else {
                appendCurrentSectionIfNeeded()
                currentSection = paragraph
            }
        }

        appendCurrentSectionIfNeeded()
        return sections
    }

    private func sendToGemini(_ text: String) {
        let userMessageID = UUID()
        messages.append(Message(id: userMessageID, text: text, isUser: true))

        if aiProvider == .gemini && effectiveGeminiApiKey.isEmpty {
            messages.append(Message(text: "Modell-Fehler: Kein Gemini-Key gesetzt.", isUser: false))
            return
        }
        if aiProvider == .groq && groqApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(Message(text: "Modell-Fehler: Kein Groq-Key gesetzt.", isUser: false))
            return
        }

        isSending = true
        let requestID = activeRequestID
        let context = buildConversationContext()
        let isExplanation = isMeaningQuestion(text)
        let topicContext = topicPromptBlock()
        let materialContext = materialContextPromptBlock()
        let feedbackGuidance = """
        - Bewerte die letzte Nutzereingabe zusaetzlich nach Natuerlichkeit wie bei einem Muttersprachler.
        - Ignoriere Satzzeichen (Punkt/Komma/Fragezeichen) bei der Bewertung.
        - Fehlende oder ersetzte Sonderzeichen/Diakritik durch Tastatur (z.B. Turkish: c/ç, g/ğ, i/ı, o/ö, s/ş, u/ü) sind allein kein WARN/BAD.
        - Achte strikt auf die Perspektive/Person des Nutzers. Ich-Form darf nicht zu Du-Form wechseln (z.B. Turkish: benim/bana/beni bleibt Ich-Form; nie senin/sana/seni).
        - Umgangssprachliche Wiederholungen oder kurze Selbstkorrekturen (z.B. "niye ... niye ...") sind nicht automatisch falsch.
        - Sei nicht streng. Kleine Fehler koennen trotzdem "OK" sein.
        - Wenn die Nutzereingabe fehlerhaft oder unklar ist, nimm die wahrscheinlich gemeinte Aussage an.
        - Gib dann in der dritten Spalte die natuerliche Korrektur dieser gemeinten Aussage aus.
        - Klassen:
          OK = grammatikalisch + semantisch passend und natuerlich.
          WARN = verstaendlich, aber unnatuerlich.
          BAD = deutliche grammatische oder semantische Abweichung.
        - Bei OK soll die dritte Spalte denselben Satz oder nur eine sehr nahe Variante enthalten.
        - Bei WARN oder BAD muss die dritte Spalte ein klar verbesserter Satz sein (nicht identisch zur Eingabe).
        - Fuege am ENDE genau eine Meta-Zeile an (ohne weitere Erklaerung):
          [FEEDBACK]|OK|<natuerlicher Satz>
          oder [FEEDBACK]|WARN|<natuerlicher Satz>
          oder [FEEDBACK]|BAD|<natuerlicher Satz>
        - Falls OK, gib trotzdem einen natuerlichen Satz in der dritten Spalte aus.
        """
        let explanationFeedbackOverride = isExplanation
            ? "- Bei reinen Bedeutungsfragen setze die Meta-Zeile bitte auf [FEEDBACK]|OK|-."
            : ""
        let prompt = """
        Du bist ein freundlicher Sprachpartner fuer \(conversationLanguageName) auf Niveau \(languageLevel.rawValue).
        Regeln:
        - Wenn es KEINE Bedeutungsfrage ist: antworte nur auf \(conversationLanguageName), ohne Sprachmix, ohne Uebersetzung.
        \(strictLanguageOnlyRule(for: conversationMode))
        - Antworte natuerlich und passend zum letzten Nutzertext, nicht mit Standardfloskeln.
        - Niveau-Regel: \(languageLevel.promptGuidance)
        - Laengen-Regel fuer normale Dialogantworten: \(responseLengthMode.promptGuidance)
        - Stelle nur dann eine Rueckfrage, wenn sie inhaltlich passt und den Dialog wirklich weiterbringt.
        - Vermeide wiederholte Rueckfragen wie immer "Und du?".
        - Keine Listen, keine langen Erklaerungen.
        - Fuehre eine lockere, intelligente Konversation mit kleinen, sinnvollen Schritten.
        - Wenn der Nutzer nach Bedeutung, Uebersetzung oder Erklaerung fragt (z.B. "was bedeutet ..."), erklaere kurz auf \(explanationLanguages).
        - Bei solchen Erklaerungsfragen: maximal 2 kurze Zeilen, insgesamt maximal 22 Woerter.
        - Gib danach nur ein mini Beispiel auf \(conversationLanguageName).
        - Gib die eigentliche Antwort als normalen Text aus.
        \(feedbackGuidance)
        \(explanationFeedbackOverride)
        \(topicContext)
        \(materialContext)
        Dialogverlauf:
        \(context)
        Nutzereingabe: \(text)
        """

        Task {
            do {
                let parsedResponse = parseTutorResponse(
                    try await generateResponse(for: prompt),
                    userText: text,
                    isExplanation: isExplanation,
                    mode: conversationMode
                )
                guard requestID == activeRequestID else { return }
                if let feedback = parsedResponse.feedback {
                    applyFeedback(feedback, toUserMessage: userMessageID)
                }
                messages.append(Message(text: parsedResponse.visibleText, isUser: false))
                speakTutorText(parsedResponse.visibleText)
            } catch {
                guard requestID == activeRequestID else { return }
                messages.append(Message(text: "Modell-Fehler: \(error.localizedDescription)", isUser: false))
            }
            if requestID == activeRequestID {
                isSending = false
                flushQueuedInputIfPossible()
            }
        }
    }

    private func generateResponse(for prompt: String) async throws -> String {
        switch aiProvider {
        case .groq:
            let service = GroqService(apiKey: groqApiKeyInput, preferredModel: storedGroqModel, temperature: modelTemperature)
            return try await service.generate(prompt: prompt)
        case .ollama:
            let service = OllamaService(baseURL: storedOllamaBaseURL, model: storedOllamaModel, temperature: modelTemperature)
            return try await service.generate(prompt: prompt)
        case .gemini:
            let service = GeminiService(apiKey: effectiveGeminiApiKey, preferredModel: effectiveGeminiModel, temperature: modelTemperature)
            return try await service.generate(prompt: prompt)
        }
    }

    private func isMeaningQuestion(_ text: String) -> Bool {
        let lower = " \(text.lowercased()) "
        let hints = [
            " was bedeutet ", " bedeutung ", " uebersetz", " übersetz",
            " erklär", " erklaer", " ne demek ", " anlamı ", " anlami ",
            " what does ", " meaning ", " what means ",
            " cosa significa ", " che significa ",
            " que significa ", " qué significa ", " que quiere decir ", " qué quiere decir ",
            " was heißt ", " was heisst ",
            " що означає ", " що це означає ", " значення ",
            " что означает ", " что значит "
        ]
        return hints.contains(where: { lower.contains($0) })
    }

    private func parseTutorResponse(
        _ rawText: String,
        userText: String,
        isExplanation: Bool,
        mode: ConversationMode
    ) -> ParsedTutorResponse {
        let extracted = extractFeedbackMeta(from: rawText)
        let visible = normalizeTutorMessage(
            extracted.cleanedText,
            isExplanation: isExplanation,
            mode: mode
        )

        let feedback = makeUserFeedback(
            originalText: userText,
            extractedLevel: extracted.level,
            extractedCorrection: extracted.correction,
            mode: mode
        )
        return ParsedTutorResponse(visibleText: visible, feedback: feedback)
    }

    private func extractFeedbackMeta(from rawText: String) -> (
        cleanedText: String,
        level: UserSentenceFeedback.Level?,
        correction: String?
    ) {
        let pattern = #"(?is)\[FEEDBACK\]\s*\|\s*(OK|WARN|BAD)\s*\|\s*(.+?)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (
                cleanedText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
                level: nil,
                correction: nil
            )
        }

        let searchRange = NSRange(rawText.startIndex..., in: rawText)
        guard let match = regex.firstMatch(in: rawText, range: searchRange) else {
            return (
                cleanedText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
                level: nil,
                correction: nil
            )
        }

        let levelToken = Range(match.range(at: 1), in: rawText).map { String(rawText[$0]) }
        let correctionToken = Range(match.range(at: 2), in: rawText).map { String(rawText[$0]) }

        var cleaned = rawText
        if let fullRange = Range(match.range(at: 0), in: cleaned) {
            cleaned.removeSubrange(fullRange)
        }
        cleaned = cleaned
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (
            cleanedText: cleaned,
            level: levelToken.flatMap { UserSentenceFeedback.Level(rawValue: $0.uppercased()) },
            correction: correctionToken
        )
    }

    private func makeUserFeedback(
        originalText: String,
        extractedLevel: UserSentenceFeedback.Level?,
        extractedCorrection: String?,
        mode: ConversationMode
    ) -> UserSentenceFeedback? {
        let original = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty else { return nil }
        let comparisonOriginal = feedbackComparisonBaseText(from: original, mode: mode)

        var correction = (extractedCorrection ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if correction == "-" || correction.isEmpty {
            correction = original
        }

        correction = correction
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if correction.count > 180 {
            correction = String(correction.prefix(180)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if correction.isEmpty {
            correction = original
        }

        correction = enforcePerspectiveConsistencyIfNeeded(
            original: comparisonOriginal,
            correction: correction,
            mode: mode
        )

        if shouldIgnoreModelCorrection(
            originalForComparison: comparisonOriginal,
            correction: correction,
            mode: mode
        ) {
            correction = comparisonOriginal
        }

        correction = sanitizeFeedbackCorrectionForDisplay(correction, mode: mode)
        if correction.isEmpty {
            correction = comparisonOriginal
        }

        let difference = sentenceDifferenceRatio(comparisonOriginal, correction)
        let localLevel = classifyFeedbackLevel(
            originalText: comparisonOriginal,
            correctionText: correction
        )
        let level = mergedFeedbackLevel(
            extractedLevel: extractedLevel,
            localLevel: localLevel,
            originalText: comparisonOriginal,
            correctionText: correction
        )

        if level == .good {
            let alternative: String?
            if difference >= 0.12 && difference <= 0.45 {
                alternative = correction
            } else {
                alternative = nil
            }
            return UserSentenceFeedback(
                level: .good,
                correction: original,
                alternative: alternative
            )
        }

        return UserSentenceFeedback(
            level: level,
            correction: correction,
            alternative: nil
        )
    }

    private func enforcePerspectiveConsistencyIfNeeded(
        original: String,
        correction: String,
        mode: ConversationMode
    ) -> String {
        switch mode {
        case .turkish:
            return enforceTurkishPerspectiveConsistency(original: original, correction: correction)
        default:
            return correction
        }
    }

    private enum TurkishPerspective {
        case firstPerson
        case secondPerson
        case mixed
        case unknown
    }

    private func turkishPerspective(in text: String) -> TurkishPerspective {
        let normalized = " \(normalizedSentenceForComparison(text)) "
        let firstMarkers = [
            " ben ", " bana ", " beni ", " benim ",
            " biz ", " bize ", " bizi ", " bizim ",
            " kendim ", " kendimi ", " kendimiz ", " kendimizi "
        ]
        let secondMarkers = [
            " sen ", " sana ", " seni ", " senin ",
            " siz ", " size ", " sizi ", " sizin ",
            " kendin ", " kendini ", " kendiniz ", " kendinizi "
        ]

        let firstHits = firstMarkers.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
        let secondHits = secondMarkers.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }

        if firstHits > 0 && secondHits > 0 { return .mixed }
        if firstHits > 0 { return .firstPerson }
        if secondHits > 0 { return .secondPerson }
        return .unknown
    }

    private func applyWordReplacements(
        _ text: String,
        replacements: [(pattern: String, replacement: String)]
    ) -> String {
        var output = text
        for item in replacements {
            output = output.replacingOccurrences(
                of: item.pattern,
                with: item.replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return output
    }

    private func enforceTurkishPerspectiveConsistency(original: String, correction: String) -> String {
        let originalPerspective = turkishPerspective(in: original)
        let correctionPerspective = turkishPerspective(in: correction)

        guard originalPerspective == .firstPerson || originalPerspective == .secondPerson else {
            return correction
        }
        guard correctionPerspective == .firstPerson || correctionPerspective == .secondPerson else {
            return correction
        }
        guard originalPerspective != correctionPerspective else {
            return correction
        }

        // If texts are far apart, keep model output to avoid forcing wrong replacements.
        if tokenDifferenceRatio(original, correction) > 0.70 {
            return correction
        }

        let fixed: String
        if originalPerspective == .firstPerson && correctionPerspective == .secondPerson {
            fixed = applyWordReplacements(
                correction,
                replacements: [
                    ("\\bsenin\\b", "benim"),
                    ("\\bsana\\b", "bana"),
                    ("\\bseni\\b", "beni"),
                    ("\\bsen\\b", "ben"),
                    ("\\bsizin\\b", "bizim"),
                    ("\\bsize\\b", "bize"),
                    ("\\bsizi\\b", "bizi"),
                    ("\\bsiz\\b", "biz")
                ]
            )
        } else if originalPerspective == .secondPerson && correctionPerspective == .firstPerson {
            fixed = applyWordReplacements(
                correction,
                replacements: [
                    ("\\bbenim\\b", "senin"),
                    ("\\bbana\\b", "sana"),
                    ("\\bbeni\\b", "seni"),
                    ("\\bben\\b", "sen"),
                    ("\\bbizim\\b", "sizin"),
                    ("\\bbize\\b", "size"),
                    ("\\bbizi\\b", "sizi"),
                    ("\\bbiz\\b", "siz")
                ]
            )
        } else {
            return correction
        }

        let fixedPerspective = turkishPerspective(in: fixed)
        if fixedPerspective == originalPerspective {
            return fixed
        }
        return correction
    }

    private func sanitizeFeedbackCorrectionForDisplay(
        _ text: String,
        mode: ConversationMode
    ) -> String {
        var cleaned = text
            .replacingOccurrences(of: "(?is)\\[FEEDBACK\\].*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\|", with: " ")
            .replacingOccurrences(
                of: "(?i)\\b(korrektur|correction|duzeltme|düzeltme|исправление|виправлення|alternatif|alternative)\\b\\s*:\\s*",
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty { return "" }

        let inLanguage = enforceConversationLanguage(cleaned, mode: mode)
        guard !inLanguage.isEmpty else { return "" }

        cleaned = inLanguage
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let sentenceParts = cleaned
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let firstSentence = sentenceParts.first {
            cleaned = firstSentence
        }

        let words = cleaned.split(whereSeparator: \.isWhitespace)
        if words.count > 18 {
            cleaned = words.prefix(18).joined(separator: " ")
        }

        return cleaned
    }

    private func feedbackComparisonBaseText(from original: String, mode: ConversationMode) -> String {
        let cleaned = original
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let extracted: String?
        switch mode {
        case .russian:
            extracted = extractRussianConversationText(from: cleaned)
        case .turkish:
            extracted = extractTurkishConversationText(from: cleaned)
        case .english:
            extracted = extractEnglishConversationText(from: cleaned)
        case .ukrainian:
            extracted = extractUkrainianConversationText(from: cleaned)
        case .italian:
            extracted = extractItalianConversationText(from: cleaned)
        case .spanish:
            extracted = extractSpanishConversationText(from: cleaned)
        case .german:
            extracted = extractGermanConversationText(from: cleaned)
        }

        if let extracted, !extracted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return extracted
        }
        return cleaned
    }

    private func isLikelySentenceInCurrentLanguage(_ text: String, mode: ConversationMode) -> Bool {
        switch mode {
        case .russian:
            return extractRussianConversationText(from: text) != nil
        case .turkish:
            return extractTurkishConversationText(from: text) != nil
        case .english:
            return extractEnglishConversationText(from: text) != nil
        case .ukrainian:
            return extractUkrainianConversationText(from: text) != nil
        case .italian:
            return extractItalianConversationText(from: text) != nil
        case .spanish:
            return extractSpanishConversationText(from: text) != nil
        case .german:
            return extractGermanConversationText(from: text) != nil
        }
    }

    private func shouldIgnoreModelCorrection(
        originalForComparison: String,
        correction: String,
        mode: ConversationMode
    ) -> Bool {
        let tokenCount = normalizedSentenceForComparison(originalForComparison).split(separator: " ").count
        guard tokenCount >= 3 else { return false }
        guard isLikelySentenceInCurrentLanguage(originalForComparison, mode: mode) else { return false }

        let charDifference = sentenceDifferenceRatio(originalForComparison, correction)
        let tokenDifference = tokenDifferenceRatio(originalForComparison, correction)

        // Model likely misunderstood the user intent and produced an unrelated rewrite.
        return charDifference >= 0.78 && tokenDifference >= 0.72
    }

    private func classifyFeedbackLevel(originalText: String, correctionText: String) -> UserSentenceFeedback.Level {
        let charDifference = sentenceDifferenceRatio(originalText, correctionText)
        let tokenDifference = tokenDifferenceRatio(originalText, correctionText)

        if charDifference <= 0.34 || tokenDifference <= 0.26 {
            return .good
        }
        if charDifference <= 0.62 || tokenDifference <= 0.52 {
            return .warning
        }
        return .bad
    }

    private func mergedFeedbackLevel(
        extractedLevel: UserSentenceFeedback.Level?,
        localLevel: UserSentenceFeedback.Level,
        originalText: String,
        correctionText: String
    ) -> UserSentenceFeedback.Level {
        guard let extractedLevel else { return localLevel }
        if extractedLevel == .good { return .good }

        let normalizedOriginal = normalizedSentenceForComparison(originalText)
        let normalizedCorrection = normalizedSentenceForComparison(correctionText)
        if normalizedOriginal == normalizedCorrection {
            return .good
        }

        let charDifference = sentenceDifferenceRatio(originalText, correctionText)
        let tokenDifference = tokenDifferenceRatio(originalText, correctionText)
        if charDifference <= 0.34 || tokenDifference <= 0.26 {
            return .good
        }

        return lessStrictLevel(extractedLevel, localLevel)
    }

    private func lessStrictLevel(
        _ lhs: UserSentenceFeedback.Level,
        _ rhs: UserSentenceFeedback.Level
    ) -> UserSentenceFeedback.Level {
        feedbackSeverity(lhs) <= feedbackSeverity(rhs) ? lhs : rhs
    }

    private func feedbackSeverity(_ level: UserSentenceFeedback.Level) -> Int {
        switch level {
        case .good:
            return 0
        case .warning:
            return 1
        case .bad:
            return 2
        }
    }

    private func tokenDifferenceRatio(_ lhs: String, _ rhs: String) -> Double {
        let leftTokens = normalizedSentenceForComparison(lhs)
            .split(separator: " ")
            .map(String.init)
        let rightTokens = normalizedSentenceForComparison(rhs)
            .split(separator: " ")
            .map(String.init)

        if leftTokens.isEmpty && rightTokens.isEmpty { return 0 }
        if leftTokens.isEmpty || rightTokens.isEmpty { return 1 }

        var leftCount: [String: Int] = [:]
        var rightCount: [String: Int] = [:]

        for token in leftTokens {
            leftCount[token, default: 0] += 1
        }
        for token in rightTokens {
            rightCount[token, default: 0] += 1
        }

        var overlap = 0
        for (token, count) in leftCount {
            overlap += min(count, rightCount[token, default: 0])
        }

        let total = leftTokens.count + rightTokens.count
        guard total > 0 else { return 0 }

        let diceScore = (2.0 * Double(overlap)) / Double(total)
        return 1.0 - diceScore
    }

    private func sentenceDifferenceRatio(_ lhs: String, _ rhs: String) -> Double {
        let left = Array(normalizedSentenceForComparison(lhs))
        let right = Array(normalizedSentenceForComparison(rhs))

        if left.isEmpty && right.isEmpty { return 0 }
        if left.isEmpty || right.isEmpty { return 1 }

        let distance = levenshteinDistance(left, right)
        let baseline = max(left.count, right.count)
        guard baseline > 0 else { return 0 }
        return Double(distance) / Double(baseline)
    }

    private func normalizedSentenceForComparison(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive], locale: Locale.current)
            .lowercased()
            .replacingOccurrences(of: "[\\p{P}\\p{S}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func levenshteinDistance(_ lhs: [Character], _ rhs: [Character]) -> Int {
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        for (leftIndex, leftChar) in lhs.enumerated() {
            var current = Array(repeating: 0, count: rhs.count + 1)
            current[0] = leftIndex + 1

            for (rightIndex, rightChar) in rhs.enumerated() {
                let substitutionCost = leftChar == rightChar ? 0 : 1
                let insertion = current[rightIndex] + 1
                let deletion = previous[rightIndex + 1] + 1
                let substitution = previous[rightIndex] + substitutionCost
                current[rightIndex + 1] = min(insertion, min(deletion, substitution))
            }

            previous = current
        }
        return previous[rhs.count]
    }

    private func normalizeTutorMessage(_ text: String, isExplanation: Bool, mode: ConversationMode) -> String {
        let shortened = shortenTutorMessage(text, isExplanation: isExplanation)
        guard !isExplanation else { return shortened }

        let forcedSingleLanguage = enforceConversationLanguage(shortened, mode: mode)
        if forcedSingleLanguage.isEmpty {
            return fallbackConversationReply(for: mode)
        }
        return forcedSingleLanguage
    }

    private func enforceConversationLanguage(_ text: String, mode: ConversationMode) -> String {
        switch mode {
        case .russian:
            return extractRussianConversationText(from: text) ?? ""
        case .turkish:
            return extractTurkishConversationText(from: text) ?? ""
        case .english:
            return extractEnglishConversationText(from: text) ?? ""
        case .ukrainian:
            return extractUkrainianConversationText(from: text) ?? ""
        case .italian:
            return extractItalianConversationText(from: text) ?? ""
        case .spanish:
            return extractSpanishConversationText(from: text) ?? ""
        case .german:
            return extractGermanConversationText(from: text) ?? ""
        }
    }

    private func extractRussianConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let best = segments.max { lhs, rhs in
            scoreRussianSegment(lhs) < scoreRussianSegment(rhs)
        }
        guard let best else { return nil }

        let cleaned = best.replacingOccurrences(
            of: "[^А-Яа-яЁё0-9\\s.,!?;:()«»\"'\\-—]",
            with: " ",
            options: .regularExpression
        )
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil else {
            return nil
        }
        return cleaned
    }

    private func extractTurkishConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreTurkishSegment($0) > scoreTurkishSegment($1) }
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^A-Za-zÇĞİÖŞÜçğıöşü0-9\\s.,!?;:()\"'\\-]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[A-Za-zÇĞİÖŞÜçğıöşü]", options: .regularExpression) != nil else { continue }
            let mixCounts = turkishGermanMixHintCounts(in: cleaned)
            let turkishChars = countMatches(in: cleaned, pattern: "[ÇĞİÖŞÜçğıöşü]")
            let turkishScore = scoreTurkishSegment(cleaned)
            let germanScore = scoreGermanSegment(cleaned)
            let hasTurkishEvidence =
                turkishChars > 0 ||
                mixCounts.turkishHits > 0 ||
                turkishScore >= germanScore + 2

            if mixCounts.germanHits > 0 && mixCounts.turkishHits > 0 { continue }
            if !hasTurkishEvidence {
                if mixCounts.germanHits == 0 && germanScore <= turkishScore + 1 {
                    return cleaned
                }
                continue
            }
            if mixCounts.germanHits >= 2 && mixCounts.germanHits >= mixCounts.turkishHits { continue }
            if germanScore > turkishScore + 3 { continue }
            return cleaned
        }

        return nil
    }

    private func extractEnglishConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreEnglishSegment($0) > scoreEnglishSegment($1) }
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^A-Za-z0-9\\s.,!?;:()\"'\\-]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[A-Za-z]", options: .regularExpression) != nil else { continue }
            let lower = " \(cleaned.lowercased()) "
            let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
            let turkishHints = [" merhaba ", " nasılsın ", " nasilsin ", " teşekkür ", " tesekkur ", " lütfen ", " lutfen "]
            let germanHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            let turkishHits = turkishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            if germanHits == 0 && turkishHits == 0 {
                return cleaned
            }
        }

        return nil
    }

    private func extractUkrainianConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreUkrainianSegment($0) > scoreUkrainianSegment($1) }
        var fallbackCandidate: String?
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^А-Яа-яЄєІіЇїҐґ0-9\\s.,!?;:()«»\"'\\-—]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[А-Яа-яЄєІіЇїҐґ]", options: .regularExpression) != nil else { continue }
            if fallbackCandidate == nil {
                fallbackCandidate = cleaned
            }

            let normalized = normalizedHintText(cleaned)
            let ukrainianHints = [" привіт ", " дякую ", " будь ласка ", " як ", " що ", " сьогодні ", " зараз ", " мені ", " тобі "]
            let russianHints = [" привет ", " спасибо ", " пожалуйста ", " как ", " что ", " сегодня ", " сейчас ", " мне ", " тебе "]
            let ukrainianHintHits = ukrainianHints.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
            let russianHintHits = russianHints.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
            let ukrainianSpecific = countMatches(in: cleaned, pattern: "[ЄєІіЇїҐґ]")
            let russianSpecific = countMatches(in: cleaned, pattern: "[ЫыЭэЁёЪъ]")
            let ukrainianScore = scoreUkrainianSegment(cleaned)
            let russianScore = scoreRussianSegment(cleaned)

            if ukrainianSpecific > 0 && russianSpecific == 0 {
                return cleaned
            }
            if ukrainianHintHits > russianHintHits && russianSpecific == 0 {
                return cleaned
            }
            if ukrainianHintHits >= 1 && russianHintHits == 0 && russianSpecific <= 1 {
                return cleaned
            }
            if russianSpecific == 0 && ukrainianScore >= russianScore + 2 {
                return cleaned
            }
        }

        return fallbackCandidate
    }

    private func extractItalianConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreItalianSegment($0) > scoreItalianSegment($1) }
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^A-Za-zÀ-ÖØ-öø-ÿ0-9\\s.,!?;:()\"'\\-]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ]", options: .regularExpression) != nil else { continue }
            let lower = " \(cleaned.lowercased()) "
            let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
            let germanHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            if germanHits == 0 {
                return cleaned
            }
        }

        return nil
    }

    private func extractSpanishConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreSpanishSegment($0) > scoreSpanishSegment($1) }
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^A-Za-zÀ-ÖØ-öø-ÿ0-9\\s.,!?;:()\"'\\-¿¡]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ]", options: .regularExpression) != nil else { continue }
            let lower = " \(cleaned.lowercased()) "
            let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
            let germanHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            if germanHits == 0 {
                return cleaned
            }
        }

        return nil
    }

    private func extractGermanConversationText(from text: String) -> String? {
        let segments = splitIntoSegments(text)
        guard !segments.isEmpty else { return nil }

        let preferred = segments.sorted { scoreGermanSegment($0) > scoreGermanSegment($1) }
        for segment in preferred {
            let cleaned = segment
                .replacingOccurrences(of: "[^A-Za-zÄÖÜäöüß0-9\\s.,!?;:()\"'\\-]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.range(of: "[A-Za-zÄÖÜäöüß]", options: .regularExpression) != nil else { continue }
            let mixCounts = germanTurkishMixHintCounts(in: cleaned)
            let germanChars = countMatches(in: cleaned, pattern: "[ÄÖÜäöüß]")
            let germanScore = scoreGermanSegment(cleaned)
            let turkishScore = scoreTurkishSegment(cleaned)
            let hasGermanEvidence =
                germanChars > 0 ||
                mixCounts.germanHits > 0 ||
                germanScore >= turkishScore + 2

            if mixCounts.turkishHits > 0 && mixCounts.germanHits > 0 { continue }
            if !hasGermanEvidence {
                if mixCounts.turkishHits == 0 && turkishScore <= germanScore + 1 {
                    return cleaned
                }
                continue
            }
            if mixCounts.turkishHits >= 2 && mixCounts.turkishHits >= mixCounts.germanHits { continue }
            if turkishScore > germanScore + 3 { continue }
            return cleaned
        }

        return nil
    }

    private func fallbackConversationReply(for mode: ConversationMode) -> String {
        switch mode {
        case .russian:
            return "Понял. Продолжим?"
        case .turkish:
            return "Anladim. Devam edelim?"
        case .english:
            return "Got it. Shall we continue?"
        case .ukrainian:
            return "Зрозуміло. Продовжимо?"
        case .italian:
            return "Capito. Continuiamo?"
        case .spanish:
            return "Entendido. Seguimos?"
        case .german:
            return "Verstanden. Machen wir weiter?"
        }
    }

    private func splitIntoSegments(_ text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: CharacterSet(charactersIn: ".!?")) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizedHintText(_ text: String) -> String {
        let lowered = text.lowercased()
        let normalized = lowered.replacingOccurrences(
            of: "[^\\p{L}0-9]+",
            with: " ",
            options: .regularExpression
        )
        return " \(normalized) "
    }

    private func turkishGermanMixHintCounts(in text: String) -> (turkishHits: Int, germanHits: Int) {
        let normalized = normalizedHintText(text)
        let turkishHints = [
            " ben ", " bana ", " beni ", " benim ", " biz ", " bize ", " bizi ", " bizim ",
            " sen ", " sana ", " seni ", " senin ",
            " niye ", " neden ", " bugün ", " bugun ", " çok ", " cok ", " için ", " icin ",
            " lütfen ", " lutfen ", " merhaba ", " nasılsın ", " nasilsin ",
            " ve ", " ama ", " çünkü ", " cunku ", " değil ", " degil ", " var ", " yok ",
            " bir ", " bu ", " şu ", " su ", " evet ", " hayır ", " hayir ", " tamam ",
            " kafam ", " ağrıyor ", " agriyor "
        ]
        let germanHints = [
            " ich ", " mich ", " mir ", " mein ", " meine ",
            " du ", " dich ", " dir ", " dein ", " deine ",
            " wir ", " ihr ", " sie ", " er ", " es ",
            " nicht ", " was ", " wie ", " warum ", " bitte ", " und ", " oder ", " aber ",
            " der ", " die ", " das ", " ein ", " eine ", " heute ", " weil ", " wenn ",
            " kann ", " ist ", " sind ", " habe ", " hast ", " haben ", " danke ", " hallo ", " gut "
        ]
        let turkishHits = turkishHints.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
        let germanHits = germanHints.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
        return (turkishHits, germanHits)
    }

    private func germanTurkishMixHintCounts(in text: String) -> (germanHits: Int, turkishHits: Int) {
        let counts = turkishGermanMixHintCounts(in: text)
        let germanHits = counts.germanHits
        let turkishHits = counts.turkishHits
        return (germanHits, turkishHits)
    }

    private func scoreRussianSegment(_ text: String) -> Int {
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁё]")
        let latin = countMatches(in: text, pattern: "[A-Za-zÄÖÜäöüßÇĞİÖŞÜçğıöşü]")
        return (cyr * 6) - (latin * 4)
    }

    private func scoreTurkishSegment(_ text: String) -> Int {
        let mixCounts = turkishGermanMixHintCounts(in: text)
        let turkishHintHits = mixCounts.turkishHits
        let germanHintHits = mixCounts.germanHits
        let turkishChars = countMatches(in: text, pattern: "[ÇĞİÖŞÜçğıöşü]")
        let latin = countMatches(in: text, pattern: "[A-Za-zÇĞİÖŞÜçğıöşü]")
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (turkishHintHits * 9) + (turkishChars * 4) + latin - (germanHintHits * 6) - (cyr * 8)
    }

    private func scoreEnglishSegment(_ text: String) -> Int {
        let lower = " \(text.lowercased()) "
        let englishHints = [" hello ", " hi ", " i ", " you ", " we ", " are ", " is ", " can ", " do ", " want ", " like ", " please ", " thanks ", " today ", " now "]
        let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let turkishHints = [" merhaba ", " nasılsın ", " nasilsin ", " teşekkür ", " tesekkur ", " lütfen ", " lutfen "]
        let englishHintHits = englishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let turkishHintHits = turkishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latin = countMatches(in: text, pattern: "[A-Za-z]")
        let turkishChars = countMatches(in: text, pattern: "[ÇĞİÖŞÜçğıöşü]")
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (englishHintHits * 8) + latin - (germanHintHits * 4) - (turkishHintHits * 4) - (turkishChars * 3) - (cyr * 10)
    }

    private func scoreUkrainianSegment(_ text: String) -> Int {
        let lower = " \(text.lowercased()) "
        let ukrainianHints = [" привіт ", " дякую ", " будь ласка ", " сьогодні ", " зараз ", " хочу ", " можу ", " так ", " ні "]
        let russianHints = [" привет ", " спасибо ", " пожалуйста ", " сегодня ", " сейчас ", " хочу ", " могу "]
        let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let ukrainianHintHits = ukrainianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let russianHintHits = russianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЄєІіЇїҐґ]")
        let ukrainianChars = countMatches(in: text, pattern: "[ЄєІіЇїҐґ]")
        let russianSpecific = countMatches(in: text, pattern: "[ЫыЭэЁёЪъ]")
        let latin = countMatches(in: text, pattern: "[A-Za-zÄÖÜäöüßÇĞİÖŞÜçğıöşü]")
        return (ukrainianHintHits * 9) + (ukrainianChars * 5) + cyr - (russianHintHits * 4) - (russianSpecific * 10) - (germanHintHits * 4) - (latin * 6)
    }

    private func scoreItalianSegment(_ text: String) -> Int {
        let lower = " \(text.lowercased()) "
        let italianHints = [" ciao ", " grazie ", " per favore ", " voglio ", " oggi ", " domani ", " posso ", " sono ", " sei "]
        let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let spanishHints = [" hola ", " gracias ", " por favor ", " quiero ", " hoy ", " manana ", " mañana "]
        let italianHintHits = italianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let spanishHintHits = spanishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latin = countMatches(in: text, pattern: "[A-Za-zÀ-ÖØ-öø-ÿ]")
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (italianHintHits * 8) + latin - (germanHintHits * 4) - (spanishHintHits * 3) - (cyr * 8)
    }

    private func scoreSpanishSegment(_ text: String) -> Int {
        let lower = " \(text.lowercased()) "
        let spanishHints = [" hola ", " gracias ", " por favor ", " quiero ", " hoy ", " manana ", " mañana ", " puedo ", " eres "]
        let germanHints = [" ich ", " nicht ", " was ", " bedeutet ", " warum ", " bitte ", " und ", " der ", " die ", " das "]
        let italianHints = [" ciao ", " grazie ", " per favore ", " voglio ", " oggi ", " domani "]
        let spanishHintHits = spanishHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let germanHintHits = germanHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let italianHintHits = italianHints.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let latin = countMatches(in: text, pattern: "[A-Za-zÀ-ÖØ-öø-ÿ]")
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (spanishHintHits * 8) + latin - (germanHintHits * 4) - (italianHintHits * 3) - (cyr * 8)
    }

    private func scoreGermanSegment(_ text: String) -> Int {
        let mixCounts = germanTurkishMixHintCounts(in: text)
        let englishHints = [" hello ", " hi ", " i ", " you ", " are ", " is ", " can ", " please ", " thanks "]
        let normalized = normalizedHintText(text)
        let germanHintHits = mixCounts.germanHits
        let turkishHintHits = mixCounts.turkishHits
        let englishHintHits = englishHints.reduce(0) { $0 + (normalized.contains($1) ? 1 : 0) }
        let germanChars = countMatches(in: text, pattern: "[ÄÖÜäöüß]")
        let latin = countMatches(in: text, pattern: "[A-Za-zÄÖÜäöüß]")
        let cyr = countMatches(in: text, pattern: "[А-Яа-яЁёІіЇїЄєҐґ]")
        return (germanHintHits * 9) + (germanChars * 4) + latin - (englishHintHits * 4) - (turkishHintHits * 6) - (cyr * 8)
    }

    private func countMatches(in text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, options: [], range: range)
    }

    private func shortenTutorMessage(_ text: String, isExplanation: Bool) -> String {
        let normalized = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s*[-•]\\s*", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return text }

        let sentenceParts = normalized.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let maxSentences = isExplanation ? 2 : responseLengthMode.sentenceLimit
        let compactBySentence = sentenceParts.prefix(maxSentences).joined(separator: ". ")
        let base = compactBySentence.isEmpty ? normalized : compactBySentence

        let maxWords: Int
        if isExplanation {
            maxWords = 22
        } else {
            maxWords = responseLengthMode.wordLimit
        }

        let words = base.split(whereSeparator: \.isWhitespace)
        let shortenedByWords = words.prefix(maxWords).joined(separator: " ")
        let candidate = shortenedByWords.isEmpty ? base : shortenedByWords

        let maxChars = isExplanation ? 160 : responseLengthMode.characterLimit
        if candidate.count <= maxChars {
            return candidate
        }

        let end = candidate.index(candidate.startIndex, offsetBy: maxChars)
        return String(candidate[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
