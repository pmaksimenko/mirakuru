$(document).ready ->
  constantPercents = true
  constantAmount = false

  calculateTotalPrice = ->
    totalPrice = 0
    $.each($('.order_object'), (index, element) ->
      price = parseInt($(element).find('.invitation_price').prop('value'))
      animatorPrice = parseInt($(element).find('.invitation_animator_money').prop('value'))
      overheads = parseInt($(element).find('.invitation_overheads').prop('value'))
      totalPrice = totalPrice + (price - animatorPrice - overheads)
    )
    additionalExpense = parseInt($('#order_dopnik').prop('value'))
    console.log(totalPrice - additionalExpense)
    totalPrice - additionalExpense

  # calculate rubls by percents
  calculatePartnerAmount = (percents) ->
    totalPrice = calculateTotalPrice()
    totalPrice / 100.0 * percents

  calculatePartnerPercents = (amount) ->
    totalPrice = calculateTotalPrice()
    parseFloat(amount) / totalPrice  * 100.0

  updateAndSetPartnerAmount = ->
    value = $('#partner_money_percents').prop('value')
    percents = parseFloat(value.replace(',', '.'))
    if percents > 100
      percents = 100
    amount = calculatePartnerAmount(percents)
    if isNaN(amount) || amount == undefined || amount < 0
      amount = 0
    amount = parseFloat((amount).toFixed(2))
    $('#order_partner_money').prop('value', amount)

  updateAndSetPartnerPercents = ->
    value = $('#order_partner_money').prop('value')
    preparedValue = parseFloat(value.replace(',', '.'))
    percents = calculatePartnerPercents(preparedValue)
    if percents > 100
      percents = 100
    if isNaN(percents) || percents == undefined
      percents = 0
    percents = parseFloat((percents ).toFixed(2))
    $('#partner_money_percents').prop('value', percents)

  updateRadioClasses = ->
    if constantPercents
      $('.partner_percents_radio').addClass('selected')
      $('.partner_amount_radio').removeClass('selected')
    else if constantAmount
      $('.partner_amount_radio').addClass('selected')
      $('.partner_percents_radio').removeClass('selected')

  updatePartnerMoney = ->
    if constantPercents
      updateAndSetPartnerAmount()
    else if constantAmount
      updateAndSetPartnerPercents()

  # ============= Events
  $('#partner_money_percents').on('keyup', (event) ->
    updateAndSetPartnerAmount()
  )

  $('#order_partner_money').on('keyup', (event) ->
    updateAndSetPartnerPercents()
  )

  $('.partner_amount_radio').on('click', (event) ->
    constantPercents = false
    constantAmount = true
    updateRadioClasses()
    updateAndSetPartnerAmount()
  )

  $('.partner_percents_radio').on('click', (event) ->
    constantPercents = true
    constantAmount = false
    updateRadioClasses()
    updateAndSetPartnerPercents()
  )

  $('#order_dopnik').on('keyup', (event) ->
    updatePartnerMoney()
  )

  $(document).on('keyup', '.invitation_price', (event) ->
    updatePartnerMoney()
  )

  $(document).on('keyup', '.invitation_animator_money', (event) ->
    updatePartnerMoney()
  )

  $(document).on('keyup', '.invitation_overheads', (event) ->
    updatePartnerMoney()
  )
