//
//  ComplicationController.swift
//  Battery WatchKit Extension
//
//  Created by Ivan Terziev on 12.08.20.
//  Copyright © 2020 Ivan Terziev. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler(.backward)
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        // Info used
        let level: Float = 0.7
        let gaugeProvider = CLKSimpleGaugeProvider.init(style: .fill, gaugeColor: UIColor.green, fillFraction: level)
        let textProvider = CLKSimpleTextProvider(text: "\(level)")
        let appText = CLKSimpleTextProvider(text: "Battery")
        
        // Go trough every supported compliction
        switch complication.family {
        case .utilitarianSmall:
            
            // Create the template
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = level
            template.textProvider = textProvider
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        case .circularSmall:
            
            // Create the template
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = level
            template.textProvider = textProvider
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        case .extraLarge:
            
            // Create the template
            let template = CLKComplicationTemplateExtraLargeRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = level
            template.textProvider = textProvider
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        case .graphicCorner:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.gaugeProvider = gaugeProvider
            template.outerTextProvider = textProvider
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        case .graphicBezel:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            circularTemplate.gaugeProvider = gaugeProvider
            circularTemplate.centerTextProvider = textProvider
            template.textProvider = appText
            template.circularTemplate = circularTemplate
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        case .graphicCircular:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            template.gaugeProvider = gaugeProvider
            template.centerTextProvider = textProvider
            
            // Pass the current timeline entry
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            
        default:
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    // MARK: - Request update
    // Stopped because of the daily limit of 50 requests or so
    //    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
    //        // Update every 15 minutes
    //        handler(NSDate(timeIntervalSinceNow: 15 * 60))
    //    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        
        // Info used
        let gaugeProvider = CLKSimpleGaugeProvider.init(style: .fill, gaugeColor: UIColor.green, fillFraction: 0.7)
        let textProvider = CLKSimpleTextProvider(text: "70")
        let textProviderExtended = CLKSimpleTextProvider(text: "Your phone has 70% batter")
        let appText = CLKSimpleTextProvider(text: "Battery")
        
        // Go trough every supported compliction
        switch complication.family {
        case .utilitarianSmall:
            
            // Create the template
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = 0.7
            template.textProvider = textProvider
            
            // Pass the template
            handler(template)
            
        case .circularSmall:
            
            // Create the template
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = 0.7
            template.textProvider = textProvider
            
            // Pass the template
            handler(template)
            
        case .extraLarge:
            
            // Create the template
            let template = CLKComplicationTemplateExtraLargeRingText()
            template.ringStyle = .closed
            template.tintColor = UIColor.green
            template.fillFraction = 0.7
            template.textProvider = textProviderExtended
            
            // Pass the template
            handler(template)
            
        case .graphicCorner:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.gaugeProvider = gaugeProvider
            template.outerTextProvider = textProvider
            
            // Pass the template
            handler(template)
            
        case .graphicBezel:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            circularTemplate.gaugeProvider = gaugeProvider
            circularTemplate.centerTextProvider = textProvider
            template.textProvider = appText
            template.circularTemplate = circularTemplate
            
            // Pass the template
            handler(template)
            
        case .graphicCircular:
            
            // Create the template
            let template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            template.gaugeProvider = gaugeProvider
            template.centerTextProvider = textProvider
            
            // Pass the template
            handler(template)
            
        default:
            handler(nil)
        }
    }
}
