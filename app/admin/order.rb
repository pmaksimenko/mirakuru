ActiveAdmin.register Order do

  filter :customer
  filter :stage, as: :select,
          collection: ->{Stage.all.map{|stage| [stage.name, stage.id]}}
  filter :performance
  filter :character
  filter :status
  filter :payed
  filter :price

  index do
    column :id
    column :customer
    column :status do |record|
      t("admin.order.statuses.#{record.status}")
    end
    column 'Персонажи' do |record|
      record.positions.map do |position|
        link_to(position.character.name, admin_character_path(position.character))
      end.join('<br>').html_safe
    end
    column 'Место' do |record|
      record.stage.name
    end
    column 'Дата и время' do |record|
      "#{record.performance_date.strftime('%Y.%m.%d')}, #{record.performance_time.strftime('%H:%M')}"
    end
    column 'Ребенок' do |record|
      record.child_name
    end
    column 'Гости' do |record|
      "#{record.guests_age_from} - #{record.guests_age_to} лет".html_safe
    end
    column :updated_at
    actions
  end

  form partial: 'form'

  action_item :view, only: :show do
    link_to 'Отправить всем', sent_to_all_admin_invitation_path
  end

  show do |order|
    attributes_table do
      row :customer
      row :contact
      row :stage
      row :status do |record|
        "<b>#{t("admin.order.statuses.#{record.status}")}</b>".html_safe
      end
      row :child_name
      row :child_birthday
      row :child_notice
      row 'Возраст гостей' do |record|
        "#{record.guests_age_from} - #{record.guests_age_to}"
      end
      row 'Дата и время' do |record|
        "#{record.performance_date.strftime('%Y.%m.%d')}, #{record.performance_time.strftime('%H:%M')}"
      end
      row :performance_duration do |record|
        "#{record.performance_duration} минут"
      end
      row 'Источник заказа' do |record|
        if record.order_source
          record.order_source.value
        end
      end
      row :partner_money
      row :additional_expense
      row :order_calculations_notice
      row :partner_payed
      row :exclude_additional_expense
      row :exclude_outcome
      row :updated_at

      render partial: 'positions', locals: {positions: order.positions}
    end
  end

  controller do

    def new
      @resource_manager = ResourcesManager.new
      @manager = Order::NewManager.new
      @order = @manager.order
      @actor_manager = Order::ActorsManager.new(@order)
    end

    def edit
      @resource_manager = ResourcesManager.new
      @manager = Order::EditManager.new(params)
      @manager.prepare_params
      @order = @manager.order
      @actor_manager = Order::ActorsManager.new(@order)
    end

    def create
      customer_constructor = OrderCustomerConstructor.new(order_params)
      customer_constructor.process!
      order_params = customer_constructor.cut_params
      stage_constructor = OrderStageConstructor.new(order_params)
      stage_constructor.process!
      order_params = stage_constructor.cut_params
      positions_params = order_params.delete(:positions)
      @order = Order.new(order_params)
      @order.contact = customer_constructor.contact
      @order.customer = customer_constructor.customer
      @order.stage = stage_constructor.stage
      @order.save
      positions_constructor = OrderPositionsConstructor.new(positions_params, @order)
      positions_constructor.process!
      @order.sent_invitations_to_all
      redirect_to admin_order_path(@order)
    end

    def update
      customer_constructor = OrderCustomerConstructor.new(order_params)
      customer_constructor.process!
      order_params = customer_constructor.cut_params
      stage_constructor = OrderStageConstructor.new(order_params)
      stage_constructor.process!
      order_params = stage_constructor.cut_params
      invitation_params = order_params.delete(:positions)
      @order = Order.find(params[:id])
      @order.assign_attributes(order_params)
      if @order.contact != customer_constructor.contact
        @order.contact = customer_constructor.contact
      end
      if @order.customer != customer_constructor.customer
        @order.customer = customer_constructor.customer
      end
      if @order.stage != stage_constructor.stage
        @order.stage = stage_constructor.stage
      end
      @order.save
      positions_constructor = OrderPositionsConstructor.new(invitation_params, @order)
      positions_constructor.process!
      redirect_to admin_order_path(@order)
    end

    def order_params
      params.require(:order).permit!
    end

  end

end

