var sortedChildren: [any LogModel] {
        // Create a single array to hold all child types
        var allChildren: [any LogModel] = []
        
        if let childActivities = self.childActivities {
            allChildren.append(contentsOf: childActivities)
        }
        if let tripLegs = self.tripLegs {
            allChildren.append(contentsOf: tripLegs)
        }
        if let interactions = self.interactions {
            allChildren.append(contentsOf: interactions)
        }
        
        // Sort the unified array by start time
        return allChildren.sorted(by: { $0.time_start < $1.time_start })
    }