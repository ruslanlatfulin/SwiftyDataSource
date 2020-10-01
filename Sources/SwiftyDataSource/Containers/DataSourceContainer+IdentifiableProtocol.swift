//
//  DataSourceContainer+IdentifiableProtocol.swift
//  SwiftyDataSource
//
//  Created by Alexey Bakhtin on 2020-07-27.
//  Copyright © 2020 EffectiveSoft. All rights reserved.
//

import Foundation

public protocol IdentifiableProtocol {
    var id: Int { get }
}

extension DataSourceContainer where ResultType: IdentifiableProtocol {
    public func indexPath(forIdentifiable object: IdentifiableProtocol) -> IndexPath?  {
        return search { (indexPath, objectInContainer) -> Bool in
            return object.id == objectInContainer.id
        }
    }
}
