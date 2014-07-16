#/app/models/spree/gateway/pay_gate.rb
class Spree::Gateway::KlarnaCheckout < Spree::Gateway
  validates :preferred_locale, :inclusion=> { :in => %w(sv-se fi-fi sv-fi nb-no de-de),:message => "Allowed locales: sv-se fi-fi sv-fi nb-no de-de" }
  preference :id, :string
  preference :shared_secret, :string

  preference :terms_url, :string
  preference :locale, :string, :default => 'de-de'

  def provider_class
    ActiveMerchant::Billing::KlarnaCheckout
  end

  def method_type
    'klarna'
  end


  def commit_payment(checkout_id)

    remote_order = client.fetch(checkout_id)

    if remote_order['status'] == "checkout_complete"
      order_id = remote_order['merchant_reference']['orderid1']
      order = Spree::Order.find_by_number(order_id)
      result = nil
      ActiveRecord::Base.transaction do
        payment = order.payments.where(:payment_method_id => self.id).first

        unless payment
          payment = order.payments.create(:amount => order.total,:payment_method => self, state: 'completed')
          order.payment_total += payment.amount
        end

        unless order.completed?
          until order.state == "complete"
            if order.next!
              order.update!
            end
          end

          order.finalize!
        end

      client.post(remote_order['id'],{status: 'created'})

      end
      result
    end

  end


  def confirmation_html(klarna_order_id)
    client.fetch(klarna_order_id)['gui']['snippet'].html_safe
  rescue Klarna::Exception=>e
    if preferred_test_mode
      e.to_s
    else
      I18n.t(:klarna_error)
    end
  end


  def klarna_order_html(order,url)
    items = order.line_items.map do |prod|
      {
          reference: prod.variant.sku,
          name: prod.variant.name,
          quantity: prod.quantity.to_i,
          unit_price: to_klarna_i(prod.price + prod.additional_tax_total),
          tax_rate: to_klarna_i(prod.additional_tax_total/prod.price),
      }
    end

    if order.shipment_total > 0
      items << {
          type: 'shipping_fee',
          reference: 'SHIPPING',
          name: 'Shipping Fee',
          quantity: 1,
          unit_price: to_klarna_i(order.shipment_total),
          tax_rate: 0,
      }
    end

    klarna_order=client.create({
          purchase_country: order.shipping_address ? order.shipping_address.country.iso : purchase_country,
          purchase_currency: order.currency,
          locale: locale,
          merchant_reference: {orderid1: order.number},
          shipping_address: ( order.shipping_address && {
              given_name: order.shipping_address.firstname,
              family_name: order.shipping_address.lastname,
              care_of: '',
              street_address: order.shipping_address.address1,
              street_name: order.shipping_address.address1,
              street_number: order.shipping_address.address2,
              postal_code: order.shipping_address.zipcode,
              city: order.shipping_address.city,
              email: order.user.email,
              phone: order.shipping_address.phone
          } ),

          cart: {
            items: items
          },
          merchant: {
            id: preferred_id,
            terms_uri:        preferred_terms_url,
            checkout_uri:     url + Spree::Core::Engine.routes.url_helpers.checkout_path,
            confirmation_uri: url + Spree::Core::Engine.routes.url_helpers.confirmation_path + "?klarna_order={checkout.order.id}&gw_id=#{self.id}",
            push_uri:         url + Spree::Core::Engine.routes.url_helpers.push_uri_path + "?klarna_order={checkout.order.id}&gw_id=#{self.id}"
          }
        })

    klarna_order['gui']['snippet'].html_safe
  rescue Klarna::Exception=>e
    if preferred_test_mode
      e.to_s
    else
      I18n.t(:klarna_error)
    end
  end

  private

  COUNTRIES = {
      :'sv-se' => 'SE',
      :'fi-fi' => 'FI',
      :'sv-fi' => 'FI',
      :'nb-no' => 'NO',
      :'de-de' => 'DE'
  }

  # CURRENCIES = {
  #     :'sv-se' => 'SEK',
  #     :'fi-fi' => 'EUR',
  #     :'sv-fi' => 'EUR',
  #     :'nb-no' => 'NOK',
  #     :'de-de' => 'EUR'
  # }

  def client
    @client ||= Klarna::Client.new(preferred_shared_secret,preferred_test_mode)
  end

  def locale
    preferred_locale.downcase
  end

  def purchase_currency
    CURRENCIES[locale.to_sym]
  end

  def purchase_country
    COUNTRIES[locale.to_sym]
  end

  def to_klarna_i(number)
    (number*100).round
  end


end
