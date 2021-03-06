module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

      def show
        respond_with(@bookkeeping_document) do |format|
          format.pdf do
            send_data @bookkeeping_document.pdf, type: 'application/pdf', disposition: 'inline'
          end
        end
      end

      def index
        # Massaging the params for the index view like Spree::Admin::Orders#index
        params[:q] ||= {}
        @search = Spree::BookkeepingDocument.by_store(current_store).accessible_by(current_ability, :index).ransack(params[:q])
        @bookkeeping_documents = @search.result
        @bookkeeping_documents = @bookkeeping_documents.where(printable_id: printable_ids) if order_focused?
        @bookkeeping_documents = @bookkeeping_documents.page(params[:page] || 1).per(30)
      end

      def generate
        @order.generate_invoice_for_order
        @order.shipments.each { |s| s.packaging_slip_for_shipment }
        redirect_to spree.admin_order_bookkeeping_documents_path(@order)
      end

      private

      def order_focused?
        params[:order_id].present?
      end

      def printable_ids
        @order.shipments.ids << @order.id
      end

      def load_order
        @order = Spree::Order.find_by(number: params[:order_id])
      end
    end
  end
end
