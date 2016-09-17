Polymer

  is: 'conpinion-select-box'

  behaviors: [
    Polymer.IronFormElementBehavior,
    Polymer.PaperInputBehavior,
    Polymer.IronControlState
  ]

  properties:
    selectables: {type: Array, value: () -> []}
    selected: {type: Array, notify: true, value: () -> []}
    suggestions: {
      type: Array, notify: true, readOnly: true,
      computed: '_computeSuggestions(_selectableItems, _selectedItems.*, _inputFieldText)'
    }
    simpleItems: {type: Boolean, value: false}
    itemIdProperty: {type: String, value: 'id'}
    itemLabelProperty: {type: String, value: 'label'}
    maximum: {type: Number, value: null}

  observers: [
    '_selectablesChanged(selectables.*, simpleItems, itemIdProperty, itemLabelProperty)',
    '_selectedChanged(selected.*, simpleItems, itemIdProperty, itemLabelProperty)',
    '_selectedItemsChanged(_selectedItems.splices)',
    '_labelInputChanged(_labelInput)'
  ]

  _showFloatLabel: false
  _selectableItems: []
  _selectedItems: []
  _selectedChangedObserverEnabled: true

  attached: () ->
    @set '_inputFieldText', ''

  _selectablesChanged: ->
    @_selectableItems = @_convertItems @selectables

  _selectedChanged: ->
    if @_selectedChangedObserverEnabled && @selected
      @_selectedItems = @_convertItems @selected

  _selectedItemsChanged: (selectedItemsSplices) ->
    @_withDisabledSelectedChangedObserver =>
      @selected = @_selectedItems.map (item) =>
        if @simpleItems
          item.label
        else
          (i for i in @selectables when i[@itemIdProperty] == item.id)[0]

  _convertItems: (items) ->
    items.map (item) =>
      {
      id: if @simpleItems then item else item[@itemIdProperty]
      label: if @simpleItems then item else @itemLabelProperty.split('.').reduce(((o, x) -> o[x]), item)
      }

  _computeSuggestions: (selectableItems, selectedChangeRecord, inputFieldText) ->
    selectableItems.filter (item) =>
      alreadySelected = @_selectedItems.filter (selectedItem) ->
        item.id == selectedItem.id
      if (alreadySelected.length > 0)
        return false
      ///.*#{inputFieldText}.*///.test item.label

  _labelInputChanged: (label) ->
    @$.dropdown.open() unless label == ''

  _handleKeyDown: (e) ->
    if e.keyCode == 13
      label = e.srcElement.value
      if label != ''
        @_selectItemByLabel label

  _computeFloatLabel: (alwaysFloatLabel, inputFieldText, selectedItemsSplices, placeholder) ->
    showFloatLabel = if alwaysFloatLabel || inputFieldText != '' || @_selectedItems.length > 0 then true else false
    @_computeAlwaysFloatLabel showFloatLabel, placeholder

  _clearInput: () ->
    @_labelInput = ''

  _unselectItem: (e) ->
    itemId = e.model.item.id
    itemIndex = @_selectedItems.map((x) -> x.id).indexOf(itemId)
    @splice '_selectedItems', itemIndex, 1

  _selectItemBySuggestion: (e) ->
    @_selectItemById e.model.item.id
    @$.dropdown.close() unless @_itemsCanBeAdded()

  _selectItemByLabel: (label) ->
    return unless @_selectedItems.filter((i) -> i.label == label).length == 0
    existingSelectablesItem = @_selectableItems.filter (i) -> i.label == label
    if @simpleItems
      @push '_selectedItems', {id: label, label: label}
      @_clearInput()
    else if existingSelectablesItem.length != 0
      @_selectItemById existingSelectablesItem[0].id

  _selectItemById: (itemId) ->
    selectedItem = @_selectableItems.filter (item) ->
      item.id == itemId
    @push '_selectedItems', selectedItem[0]
    @_clearInput()

  _computeMenuVerticalOffset: (noLabelFloat) ->
    if noLabelFloat then -4 else 68

  _withDisabledSelectedChangedObserver: (f) ->
    @_selectedChangedObserverEnabled = false
    f.apply()
    @_selectedChangedObserverEnabled = true

  _itemsCanBeAdded: ->
    if @maximum then @_selectedItems.length < @maximum else true

  _isSuggestionsEnabled: ->
    !@disabled && @_itemsCanBeAdded()

  _toggleSuggestions: ->
    @$.dropdown.toggle() if @_itemsCanBeAdded()
