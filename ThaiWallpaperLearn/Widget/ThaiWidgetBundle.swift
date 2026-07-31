import WidgetKit
import SwiftUI

@main
struct ThaiWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThaiWidget()
        EnglishFirstWidget()
        ThaiWordHalfWidget()
        ThaiMeaningHalfWidget()
    }
}
