$(document).ready ->
  selectedHours = {}
  charactersCollection = {}
  charactersBlocks = {}

  mainHoursBlocks = {}
  mainSubHoursBlocks = {}

  charactersHoursBlocks = {}
  charactersSubHoursBlocks = {}

  performanceDate = null

  orderInfo = {}

  minutesToHours = {
    '15': 1,
    '30': 1,
    '45': 1,
    '60': 1,
    '90': 2,
    '120': 2,
    '180': 3
  }
  # ------------------ TIME ACTORS ----------
  # on time change - refresh occupation time
  updateOccupationTime = ->
    objectName = $('#objects_selector').val()
    if objectName != ''
      loadActorsTable(objectName)
    else
      console.log('Choose object first')

  clearHoursBlockStyles = (element) ->
    $(element).removeClass('selected')
    $(element).removeClass('occupied')
    $(element).removeClass('partly_selected')
    $(element).removeClass('disabled')

  redrawHoursBlocks = (hourLentElemnt, MainHoursCollection, subHoursCollection) ->
    redrawParltyOccupiedHoursBlocks(hourLentElemnt, subHoursCollection)

    hourKeys = Object.keys(MainHoursCollection)
    $.each(hourKeys, (index, hourKey) ->
      element = hourLentElemnt.find('.hour_selector[data-hour=' + hourKey + ']')
      collectionHour = MainHoursCollection[hourKey]

      if collectionHour.selected
        clearHoursBlockStyles(element)
        $(element).addClass('selected')
        $(element).prop('title' , 'Основное выбранное время')
      else if collectionHour.occupied
        clearHoursBlockStyles(element)
        $(element).addClass('occupied')
        $(element).prop('title' , 'В это время актер занят')
      else if collectionHour.disabled
        clearHoursBlockStyles(element)
        $(element).addClass('disabled')
        $(element).prop('title' , 'Нет доступных актеров на это время')
      else if subHoursCollection[hourKey]
        # do nothing
      else
        clearHoursBlockStyles(element)
        $(element).prop('title' , 'Доступные для выбора часы')
    )

  redrawParltyOccupiedHoursBlocks = (hourLentElemnt, collection) ->
    hourKeys = Object.keys(collection)
    $.each(hourKeys, (index, hourKey) ->
      element = hourLentElemnt.find('.hour_selector[data-hour=' + hourKey + ']')
      collectionHour = collection[hourKey]
      if collectionHour
        $(element).addClass('partly_selected')
        $(element).prop('title' , 'Выбранное время (по продолжительности)')
    )

  updateCharactersHoursBlocks = (occupationByCharacters) ->
    characterIds = Object.keys(occupationByCharacters)
    $.each(characterIds, (index, characterId) ->
      # initialize characters hashes of data
      charactersHoursBlocks[characterId] = {}
      charactersSubHoursBlocks[characterId] = {}
      initializeHoursBlocks(charactersHoursBlocks[characterId], charactersSubHoursBlocks[characterId])

      hours = occupationByCharacters[characterId]
      $.each(hours, (index, hour) ->
        # initialize characters hashes of data, set occupation
        charactersHoursBlocks[characterId][hour]['occupied'] = true
        charactersSubHoursBlocks[characterId][hour] = false
        mainHoursBlocks[hour]['disabled'] = true
      )
      redrawHoursBlocks(
        $('.character_' + characterId).find('.hours_lent'),
        charactersHoursBlocks[parseInt(characterId)],
        charactersSubHoursBlocks[parseInt(characterId)]
      )
      # update partly selection

      partlySelectHours(characterPerformanceDuration(characterId),
        charactersHoursBlocks[parseInt(characterId)],
        charactersSubHoursBlocks[parseInt(characterId)]
      )
    )

  clearCharactersOccupation = ->
    characterIds = Object.keys(charactersHoursBlocks)
    $.each(characterIds, (index, characterId) ->
      hours = Object.keys(charactersHoursBlocks[characterId])
      $.each(hours, (index, hour) ->
        charactersHoursBlocks[characterId][hour] = { selected: false, partlySelected: false, occupied: false }
      )
      redrawHoursBlocks(
        $('.character_' + characterId).find('.hours_lent'),
        charactersHoursBlocks[parseInt(characterId)],
        charactersSubHoursBlocks[parseInt(characterId)]
      )
    )

  clearMainHoursLentOccupation = ->
    hoursKeys = Object.keys(mainHoursBlocks)
    $.each(hoursKeys, (index, hourKey) ->
      mainHoursBlocks[hourKey] = { selected: false, partlySelected: false, disabled: false }
    )
    redrawHoursBlocks($('.hours_lent.main'), mainHoursBlocks, mainSubHoursBlocks)

  characterPerformanceDuration = (characterId) ->
    parseInt($('.character_' + characterId).find('.character_duration').val())

  loadActorsTable = (objectName) ->
    $.ajax
      type: 'POST',
      url: '/api/actors/occupation_time',
      data: {
        date: performanceDate,
        object_name: objectName
      }
      success: (data) ->
        clearMainHoursLentOccupation()
        clearCharactersOccupation()
        $.each(Object.keys(data.occupation_time), (characterId, index) ->
          charactersBlocks[characterId] = {}
          charactersSubHoursBlocks[characterId] = {}
          initializeHoursBlocks(charactersBlocks[characterId], charactersSubHoursBlocks[characterId])
        )
        updateCharactersHoursBlocks(data.occupation_time)
        redrawHoursBlocks($('.hours_lent.main'), mainHoursBlocks, mainSubHoursBlocks)

  # -----------------------------------------

  initializeCalendar = ->
    $('#calendar').datetimepicker({
      inline: true,
      sideBySide: false,
      locale: 'ru',
      format: 'DD.MM.YYYY'
    }).on('dp.change', (event) ->
      performanceDate = event.date.format()
      updateOccupationTime()
      clearOrder()
    )

  selectHour = (duration, hour, collection, subCollection) ->
    if !canSelectHours(duration, hour)
      return
    value = !collection[hour]['selected']
    collection[hour]['selected'] = value
    partlySelectHours(
      duration,
      collection,
      subCollection
    )

  partlySelectHours = (duration, collection, subCollection) ->
    hoursCount = minutesToHours[duration]
    hoursKeys = Object.keys(subCollection)
    $.each(hoursKeys, (index, hourKey) ->
      # disable all
      subCollection[hourKey] = false
    )
    $.each(hoursKeys, (index, mainHour) ->
      # enable only with selected
      if collection[mainHour].selected
        index = 1
        while index < hoursCount
          subHour = parseInt(mainHour) + parseInt(index)
          subCollection[subHour] = true
          index = index + 1
    )

  canSelectHours = (duration, hour) ->
    hoursCount = minutesToHours[duration]
    hour + hoursCount - 1 < 24

  # use select2 to search objects
  initializeSearcher = ->
    $('#objects_selector').select2({theme: "bootstrap"})

  # load object (any class)
  loadObjects = (objectName, callback) ->
    $.ajax
      type: 'GET',
      url: '/api/order_objects/' + objectName,
      success: (data) ->
        callback(data.container)

  redrawCharactersBlocks = (content) ->
    $('.partner_object_box').empty()
    $('.partner_object_box').append(content)

  copyMainDuration = ->
    mainDuration = $('#performance_duration').val()
    $('.character_duration').val(mainDuration)

  initializeHoursBlocks = (collection, subCollection) ->
    hour = 7
    while hour < 24
      collection[hour] = { selected: false, partlySelected: false, occupied: false }
      # default value for sub data
      subCollection[hour] = false
      hour = hour + 1

  validateCharactersHours = (characterIds) ->
    valid = false
    $.each(characterIds, (index, characterId) ->
      characterHours = charactersHoursBlocks[characterId]
      $.each(Object.keys(characterHours), (index, hourKey) ->
        if characterHours[hourKey].selected
          valid = true
      )
    )
    valid

  clearOrder = ->
    orderInfo = {}
    $('.order_row').remove()

  addToOrder = ( characterIds ) ->
    orderInfo = {}
    $.each(characterIds, (index, characterId) ->
      orderInfo[characterId] = { hours: {} }
      characterHours = charactersHoursBlocks[characterId]
      $.each(Object.keys(characterHours), (index, hourKey) ->
        if characterHours[hourKey].selected || charactersSubHoursBlocks[hourKey]
          orderInfo[characterId].hours[hourKey] = true
      )
      orderInfo[characterId]['name'] = $('.character_' + characterId).find('.name').text()
      orderInfo[characterId]['timeRange'] = characterHoursStartStop(characterId)
      orderInfo[characterId]['hoursCount'] = orderInfo[characterId].timeRange.stop - orderInfo[characterId].timeRange.start
      console.log(orderInfo[characterId])
    )

    redrawOrderInfo()

  redrawOrderInfo = ->
    $('.order_row').remove()
    if Object.keys(orderInfo).length > 0
      $('#order_block').show()
    else
      $('#order_block').hide()

    $.each(Object.keys(orderInfo), (index, characterId) ->
      htmlBlock = '<div class="row order_row"><div class="col-md-6">' +
        orderInfo[characterId].name +
        ' - ' +
        orderInfo[characterId].hoursCount +
        ' часа, c ' +
        orderInfo[characterId].timeRange.start +
        ' до ' +
        orderInfo[characterId].timeRange.stop +
        '<a href="#"><span class="glyphicon glyphicon-remove"></span></a>'
      $('#order_block').find('.title_row').after(htmlBlock)
    )

  characterHoursStartStop = (characterId) ->
    ranges = {}
    rangeIndex = 0
    characterHours = charactersHoursBlocks[characterId]
    characterSubHours = charactersSubHoursBlocks[characterId]

    $.each(Object.keys(characterHours), (index, hourKey) ->
      if characterHours[hourKey].selected || characterSubHours[hourKey]
        if ranges[rangeIndex] == undefined
          ranges[rangeIndex] = { start: parseInt(hourKey), stop: null }
        if hourKey == '23'
          ranges[rangeIndex].stop = 24
      else
        if ranges[rangeIndex] != undefined
          ranges[rangeIndex].stop = parseInt(hourKey)
          rangeIndex = rangeIndex + 1
    )

    maxRangeSize = 0
    maxKey = null
    $.each(Object.keys(ranges), (index, key) ->
      rangeSize = ranges[key].stop - ranges[key].start
      if rangeSize > maxRangeSize
        maxRangeSize = rangeSize
        maxKey = key
    )
    ranges[maxKey]

  # === Events ============================================================================
  # hours select boxes
  $(document).on('click', '.hour_selector', (event) ->
    hour = $(this).data('hour')
    if mainHoursBlocks[hour].disabled
      return false

    if $(this).parent().prop('class').match(/main/)
      duration = parseInt($('#performance_duration').val())
      selectHour(duration, hour, mainHoursBlocks, mainSubHoursBlocks)
      redrawHoursBlocks($('.hours_lent.main'), mainHoursBlocks, mainSubHoursBlocks)
    else
      characterId = parseInt($(this).parent().data('character'))
      duration = characterPerformanceDuration(characterId)
      selectHour(duration, hour, charactersHoursBlocks[characterId], charactersSubHoursBlocks[characterId])
      redrawHoursBlocks($(this).parent(), charactersHoursBlocks[characterId], charactersSubHoursBlocks[characterId])
  )

  # select and load objects / characters
  $('#objects_selector').on('change', (event) ->
    objectName = $(this).val()
    loadObjects(objectName, (data) ->
      redrawCharactersBlocks(data)
      updateOccupationTime()
      copyMainDuration()
    )
  )

  $(document).on('click', '.add_to_order', (event) ->
    container = $(this).parents('.performance_container')
    lents = container.find('.hours_lent')
    characterIds = []
    $.each(lents, (index, lent) ->
      characterIds.push(parseInt($(lent).data('character')))
    )
    errorText = []
    charactersTimeValid = validateCharactersHours(characterIds)
    childNameValid = (container.find('.child_name').prop('value') != '')
    if !charactersTimeValid
      errorText.push('Необхоидимо выбрать время')
    if !childNameValid
      errorText.push('Необходимо указать имя ребенка')

    if !childNameValid || !charactersTimeValid
      container.find('.errors').text(errorText.join(', '))
    else
      container.find('.errors').text('')

    if childNameValid && charactersTimeValid
      addToOrder(characterIds)
  )
  # ========================================================================================

  # === Initial state
  initializeCalendar()
  initializeSearcher()
  initializeHoursBlocks(mainHoursBlocks, mainSubHoursBlocks)

  date = new Date();
  performanceDate = date.toTimeString()
