//
//  LifeEventMetrics.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//


struct LifeEventMetrics: Codable, Hashable {
    /// Subjective importance to your life (impact)
    var importance: Int? = nil
    
    /// Stress level (negative arousal)
    var stress: Int? = nil
    
    /// Mood level (negative - positive)
    var mood: Int? = nil
    
    /// Energy level (activation / vitality)
    var energy: Int? = nil
    
    /// Focus or engagement during the event
    var engagement: Int? = nil
    
    /// Optional tag for physical or emotional fatigue
    var fatigue: Int? = nil
    
}
