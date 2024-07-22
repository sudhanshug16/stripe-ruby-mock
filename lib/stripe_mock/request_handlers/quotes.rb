module StripeMock
  module RequestHandlers
    module Quotes

      def Quotes.included(klass)
        klass.add_handler 'post /v1/quotes',                     :new_quote
        klass.add_handler 'post /v1/quotes/([^/]*)',             :update_quote
        klass.add_handler 'get /v1/quotes/((?!search)[^/]*)',    :get_quote
        klass.add_handler 'delete /v1/quotes/([^/]*)',           :delete_quote
        klass.add_handler 'get /v1/quotes',                      :list_quotes
        klass.add_handler 'get /v1/quotes/search',               :search_quotes
        klass.add_handler 'post /v1/quotes/([^/]*)/cancel',        :cancel_quote
        klass.add_handler 'get /v1/quotes/([^/]*)/line_items',   :get_quote_line_items
      end

      def new_quote(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        params[:id] ||= new_id('qt')
        quotes[stripe_account] ||= {}
        quotes[stripe_account][params[:id]] = Data.mock_quote(params)
        quotes[stripe_account][params[:id]]
      end

      def update_quote(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        quote = assert_existence :quote, $1, quotes[stripe_account][$1]
        quote.merge!(params)
        quote
      end

      def delete_quote(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        assert_existence :quote, $1, quotes[stripe_account][$1]
        quotes[stripe_account][$1] = {
          id: quotes[stripe_account][$1][:id],
          deleted: true
        }
      end

      def get_quote(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        quote = assert_existence :quote, $1, quotes[stripe_account][$1]
        quote.clone
      end

      def list_quotes(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        Data.mock_list_object(quotes[stripe_account]&.values, params)
      end

      SEARCH_FIELDS = ["customer", "status", "amount"].freeze
      def search_quotes(route, method_url, params, headers)
        require_param(:query) unless params[:query]
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        all_quotes = quotes[stripe_account]&.values
        results = search_results(all_quotes, params[:query], fields: SEARCH_FIELDS, resource_name: "quotes")
        Data.mock_list_object(results, params)
      end

      def cancel_quote(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        quote = assert_existence :quote, $1, quotes[stripe_account][$1]
        quote[:status] = 'canceled'
        quote
      end

      def get_quote_line_items(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        quote = assert_existence :quote, $1, quotes[stripe_account][$1]
        line_items = quote[:line_items] || []
        Data.mock_list_object(line_items, params)
      end
    end
  end
end
