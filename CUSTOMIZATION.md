# Kaui customization

In order to customize Kaui (white-label, add deep links, etc.):

1. Create a standard [Rails mountable Engine](https://guides.rubyonrails.org/engines.html). You can use the [deposit-ui engine](https://github.com/killbill/killbill-deposit-ui) as a template.
2. Configure Kaui to use your engine by setting the environment variable `KAUI_ADDITIONAL_ENGINES` (which must point to the engine name to `require`). You can also override the root route using `KAUI_ROOT` (e.g. `acme/my_controller#index`).
3. You can drop the engine and its dependencies in the war directly. Alternatively, you can do so via a `Gemfile.overlay` file if you are using bundler in your build (e.g. if you are building custom Docker image).
4. In your engine (`lib/acme/engine.rb`), mount your engine to the main Kaui app :
```ruby
module Acme
  class Engine < ::Rails::Engine
    isolate_namespace Acme

    config.assets.precompile += %w( acme/acme.css )

    config.acme_engine = ActiveSupport::OrderedOptions.new
    initializer('acme_engine.configuration') do |app|
      app.routes.append { mount Acme::Engine => '/acme', :as => 'acme_engine' }

      Acme.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
    end
    initializer('local_helper.action_controller') do
      ActiveSupport.on_load :action_controller do
        helper Acme::ApplicationHelper
      end
    end
  end
end
```
5. In your engine, create an initializer `config/initializers/customization.rb` with your customizations:
```ruby
class ActionController::Base
  before_action :do_something

  def do_something
  end
end

module Kaui
  # Custom site layout (useful for whitelabeling: you can copy the ones from Kaui and update them to your needs)
  self.layout = 'acme/layouts/acme_application'

  self.home_path = lambda { '/acme' }

  # Custom partial to render bundle details
  self.bundle_details_partial = 'acme/bundles/bundle_details'

  # Account identifier in the nav bar
  self.pretty_account_identifier = lambda { |account| account.name }

  # Display pretty plan name & subscription id associated with the invoice item on the refund screen
  self.refund_invoice_description = lambda {(index, ii, bundle_result) { ii.pretty_plan_name+' SUBSCRIPTION ID: '+ii.subscription_id }}

  # Columns to display in the account search page
  self.account_search_columns = lambda do |account=nil, view_context=nil|
    [
      ['External key', 'Balance'],
      [
        account&.external_key,
        account.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(account.balance_to_money)
      ]
    ]
  end

  # Columns to display in the invoices listing page
  self.invoice_search_columns = lambda do |invoice = nil, view_context = nil, _cached_options_for_klient = nil|
    default_label = 'label-info'
    default_label = 'label-default' if invoice&.status == 'DRAFT'
    default_label = 'label-success' if invoice&.status == 'COMMITTED'
    default_label = 'label-danger' if invoice&.status == 'VOID'
    [
      %w[Date Status],
      [
        invoice&.invoice_date,
        invoice.nil? || view_context.nil? ? nil : view_context.content_tag(:span, invoice.status, class: ['label', default_label])
      ]
    ]
  end

  # Columns to display in the account invoices listing page
  self.account_invoices_columns = lambda do |invoice=nil, view_context=nil|
    default_label = 'label-info'
    default_label = 'label-default' if invoice&.status == 'DRAFT'
    default_label = 'label-success' if invoice&.status == 'COMMITTED'
    default_label = 'label-danger' if invoice&.status == 'VOID'
    [
      ['Date', 'Amount', 'Balance', 'Status'],
      [
        invoice&.invoice_date,
        invoice.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(invoice.amount_to_money),
        invoice.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(invoice.balance_to_money),
        invoice.nil? || view_context.nil? ? nil : view_context.content_tag(:span, invoice.status, class: ['label', default_label])
      ]
    ]
  end

  # Link to the customer invoice (HTML, PDF, etc.)
  self.customer_invoice_link = lambda { |invoice, ctx| ctx.link_to 'View customer invoice html', ctx.kaui_engine.show_html_invoice_path(invoice.invoice_id), :class => 'btn', :target => '_blank' }

  # How bundle keys are displayed in the account timeline
  self.bundle_key_display_string = ->(bundle_key) { bundle_key }

  # Default plugin name to use in payment method forms
  self.creditcard_plugin_name = -> { '__EXTERNAL_PAYMENT__' }

  # Default reason codes for chargebacks
  self.chargeback_reason_codes = ['400 - Canceled Recurring Transaction',
                                  '401 - Cardholder Disputes Quality of Goods or Services' ]

  # Default reason codes for credits
  self.credit_reason_codes = ['100 - Courtesy',
                              '101 - Billing Error',
                              '199 - OTHER']

  # Default reason codes for item adjustments
  self.invoice_item_reason_codes = ['100 - Courtesy',
                                    '101 - Billing Error',
                                    '199 - OTHER']

  # Default reason codes for payments
  self.payment_reason_codes = ['600 - Alt payment method',
                               '699 - OTHER']

  # Default reason codes for refunds
  self.refund_reason_codes = ['500 - Courtesy',
                              '501 - Billing Error',
                              '502 - Alt payment method',
                              '599 - OTHER']

  # Deep links to payment gateways
  self.gateways_urls = {
    'killbill-adyen' => 'https://ca-test.adyen.com/ca/ca/accounts/showTx.shtml?txType=Payment&pspReference=FIRST_PAYMENT_REFERENCE_ID',
    'killbill-cybersource' => 'https://ebctest.cybersource.com/ebctest/transactionsearch/TransactionSearchDetailsLoad.do?requestId=FIRST_PAYMENT_REFERENCE_ID',
    'killbill-stripe' => 'https://dashboard.stripe.com/test/payments/FIRST_PAYMENT_REFERENCE_ID'
  }
end
```

When modifying the layouts, make sure to import your additional CSS files as needed in `acme_application.html.erb`, e.g.:

```erbruby
<%= stylesheet_link_tag 'acme/acme' %>
```
