//
//  SelectablesListViewController.swift
//  launchOptions
//
//  Created by Alexey Bakhtin on 10/1/18.
//  Copyright © 2018 launchOptions. All rights reserved.
//

import UIKit

open class SelectablesListViewController<T>: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, TableViewDataSourceDelegate where T: SelectableEntity {

    // MARK: Public
    
    public init(container: DataSourceContainer<T>? = nil,
                selected: [T]? = nil,
                multiselection: Bool = false,
                cellUsesCustomSelection: Bool = false) {
        super.init(style: .plain)
        self.container = container
        self.dataSource.container = container
        self.selectedEntries = selected ?? []
        self.multiselection = multiselection
        self.cellUsesCustomSelection = cellUsesCustomSelection
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var container: DataSourceContainer<T>? {
        didSet {
            self.dataSource.container = container
        }
    }
    
    public var delegate: AnySelectablesListDelegate<T>?
    public var didSelectAction: ((T) -> ())?
    public var didSelectMultiAction: (([T]) -> ())?

    open func cellIdentifier() -> String {
        return SelectablesListCell.defaultReuseIdentifier
    }
    
    open func headerIdentifier() -> String? {
        return nil
    }

    open func headerHeight() -> CGFloat {
        return headerIdentifier() == nil ? 0.0 : 66.0
    }
    
    open func registerCell() {
        tableView.registerCellClassForDefaultIdentifier(SelectablesListCell.self)
    }
    

    // MARK: Actions
    
    @objc private func done(_ sender: AnyObject) {
        didSelectMultiAction?(selectedEntries)
        delegate?.listDidSelect(self, entities: selectedEntries)
    }
    
    // MARK: View life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Multiple selection allows to deselect single choise
        // In this controller single selection is processed on didSelectAction
        tableView.allowsMultipleSelection = true
        registerCell()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        
        if container is FilterableDataSourceContainer {
            definesPresentationContext = true
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }

        dataSource.tableView = tableView
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectRowsForSelectedEntries()
    }
    
    // MARK: DataSource
    
    public lazy var dataSource: TableViewDataSource<T> = {
        let dataSource = TableViewDataSource<T>(container: container, delegate: AnyTableViewDataSourceDelegate(self))
        dataSource.cellIdentifier = cellIdentifier()
        dataSource.headerIdentifier = headerIdentifier()
        dataSource.headerHeight = headerHeight()
        return dataSource
    }()
    
    
    // MARK: Private

    private var multiselection: Bool = false
    private var cellUsesCustomSelection: Bool = false
    public private(set) var selectedEntries: [T] = []
    private var allowTextSearch: Bool {
        return container is FilterableDataSourceContainer<T>
    }
    
    public lazy var searchController: UISearchController? = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("FIND", comment: "")
        searchController.searchBar.setImage(UIImage(named: "searchbar-icon"), for: .search, state: .normal)
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.showsSearchResultsButton = true
        return searchController
    }()


    fileprivate func selectRowsForSelectedEntries() {
        selectedEntries.forEach { entry in
            container?.search({ (indexPath, entity) -> Bool in
                let selected = entity.selectableEntityIsEqual(to: entry) == true
                if selected {
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
                return selected
            })
        }
    }

    // MARK: UISearchResultsUpdating
    
    open func updateSearchResults(for searchController: UISearchController) {
        (container as? FilterableDataSourceContainer)?.filterData(by: searchController.searchBar.text)
        tableView.reloadData()
        selectRowsForSelectedEntries()
    }

    // MARK: UISearchBarDelegate

    open func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchBar.endEditing(true)
    }
    
    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchBar.endEditing(true)
    }

    open func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T, at indexPath: IndexPath) {
        didSelectAction?(object)
        selectedEntries.append(object)
        delegate?.listDidSelect(self, object)

        if multiselection == false {
            selectedEntries = [object]
            if let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows {
                for indexPathForSelectedRow in indexPathsForSelectedRows {
                    if indexPathForSelectedRow != indexPath {
                        tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
                    }
                }
            }
        }
    }
    
    open func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: T, at indexPath: IndexPath?) {
        if let index = selectedEntries.firstIndex(where: { $0.selectableEntityIsEqual(to: object)}) {
            selectedEntries.remove(at: index)
            delegate?.listDidDeselect(self, object)
        }
    }
    
    public func isObjectSelected(_ object: T) -> Bool {
        return selectedEntries.contains(where: { $0.selectableEntityIsEqual(to: object) })
    }
}

open class SelectablesListCell: UITableViewCell, DataSourceConfigurable {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    open func setup() {
        contentView.addSubview(label)
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 15).isActive = true
        label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15).isActive = true
        label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15).isActive = true
    }
    
    public func configure(with object: Any) {
        self.entity = object as? SelectableEntity
    }
    
    open var entity: SelectableEntity? {
        didSet {
            label.attributedText = entity?.selectableEntityDescription
        }
    }
}
