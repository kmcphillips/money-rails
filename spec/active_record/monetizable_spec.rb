require 'spec_helper'

describe MoneyRails::ActiveRecord::Monetizable do

  describe "monetize" do
    before :each do
      @product = Product.create(:price_cents => 3000, :discount => 150,
                                :bonus_cents => 200)
      @service = Service.create(:charge_cents => 2000, :discount_cents => 120)
    end

    it "attaches a Money object to model field" do
      @product.price.should be_an_instance_of(Money)
      @product.discount_value.should be_an_instance_of(Money)
      @product.bonus.should be_an_instance_of(Money)
    end

    it "returns the expected money amount as a Money object" do
      @product.price.should == Money.new(3000, "USD")
    end

    it "assigns the correct value from a Money object" do
      @product.price = Money.new(3210, "USD")
      @product.save.should be_true
      @product.price_cents.should == 3210
    end

    it "respects :as argument" do
      @product.discount_value.should == Money.new(150, "USD")
    end

    it "uses numericality validation" do
      @product.price_cents = "foo"
      @product.save.should be_false

      @product.price_cents = 2000
      @product.save.should be_true
    end

    it "doesn't allow nil by default" do
      @product.price_cents = nil
      @product.save.should be_false
    end

    it "allows nil if optioned" do
      @product.optional_price_cents = nil
      @product.save.should be_true
      @product.optional_price.should be_nil
    end

    it "uses Money default currency if :with_currency has not been used" do
      @service.discount.currency.should == Money::Currency.find(:eur)
    end

    it "overrides default currency with the currency registered for the model" do
      @product.price.currency.should == Money::Currency.find(:usd)
    end

    it "overrides default currency with the value of :with_currency argument" do
      @service.charge.currency.should == Money::Currency.find(:usd)
      @product.bonus.currency.should == Money::Currency.find(:gbp)
    end

    it "assigns correctly Money objects to the attribute" do
      @product.price = Money.new(2500, :USD)
      @product.save.should be_true
      @product.price.cents.should == 2500
      @product.price.currency_as_string.should == "USD"
    end

    it "assigns correctly Fixnum objects to the attribute" do
      @product.price = 25
      @product.save.should be_true
      @product.price.cents.should == 2500
      @product.price.currency_as_string.should == "USD"

      @service.discount = 2
      @service.save.should be_true
      @service.discount.cents.should == 200
      @service.discount.currency_as_string.should == "EUR"
    end

    it "assigns correctly String objects to the attribute" do
      @product.price = "25"
      @product.save.should be_true
      @product.price.cents.should == 2500
      @product.price.currency_as_string.should == "USD"

      @service.discount = "2"
      @service.save.should be_true
      @service.discount.cents.should == 200
      @service.discount.currency_as_string.should == "EUR"
    end

    it "overrides default, model currency with the value of :with_currency in fixnum assignments" do
      @product.bonus = 25
      @product.save.should be_true
      @product.bonus.cents.should == 2500
      @product.bonus.currency_as_string.should == "GBP"

      @service.charge = 2
      @service.save.should be_true
      @service.charge.cents.should == 200
      @service.charge.currency_as_string.should == "USD"
    end

    it "overrides default, model currency with the value of :with_currency in string assignments" do
      @product.bonus = "25"
      @product.save.should be_true
      @product.bonus.cents.should == 2500
      @product.bonus.currency_as_string.should == "GBP"

      @service.charge = "2"
      @service.save.should be_true
      @service.charge.cents.should == 200
      @service.charge.currency_as_string.should == "USD"
    end

    it "overrides default currency with model currency, in fixnum assignments" do
      @product.discount_value = 5
      @product.save.should be_true
      @product.discount_value.cents.should == 500
      @product.discount_value.currency_as_string.should == "USD"
    end

    it "overrides default currency with model currency, in string assignments" do
      @product.discount_value = "5"
      @product.save.should be_true
      @product.discount_value.cents.should == 500
      @product.discount_value.currency_as_string.should == "USD"
    end

    it "falls back to default currency, in fixnum assignments" do
      @service.discount = 5
      @service.save.should be_true
      @service.discount.cents.should == 500
      @service.discount.currency_as_string.should == "EUR"
    end

    it "falls back to default currency, in string assignments" do
      @service.discount = "5"
      @service.save.should be_true
      @service.discount.cents.should == 500
      @service.discount.currency_as_string.should == "EUR"
    end

    it "sets field to nil, in nil assignments if allow_nil is set" do
      @product.optional_price = nil 
      @product.save.should be_true
      @product.optional_price.should be_nil
    end

    it "sets field to nil, when passed in a blank and allow_nil is set" do
      @product.optional_price = ""
      @product.save.should be_true
      @product.optional_price.should be_nil
    end

    it "sets field to nil via attributes hash, when allow_nil is set" do
      @product = Product.new :price_cents => 3000, :discount => 150, :bonus_cents => 200
      @product.save.should be_true
      @product.optional_price.should be_nil
    end

    it "sets field to nil via attributes hash, when passed in a blank and allow_nil is set" do
      @product = Product.new :optional_price => "", :price_cents => 3000, :discount => 150, :bonus_cents => 200
      @product.save.should be_true
      @product.optional_price.should be_nil
    end

    it "sets field to nil, in blank assignments if allow_nil is set" do
      pending "composed_of doen't current support nil contructor values" do
        @product.optional_price = "" 
        @product.save.should be_true
        @product.optional_price.should be_nil
      end
    end
    
    context "for model with currency column:" do
      before :each do
        @transaction = Transaction.create(:amount_cents => 2400, :tax_cents => 600,
                                          :currency => :usd)
        @dummy_product1 = DummyProduct.create(:price_cents => 2400, :currency => :usd)
        @dummy_product2 = DummyProduct.create(:price_cents => 2600) # nil currency
      end

      it "overrides default currency with the value of row currency" do
        @transaction.amount.currency.should == Money::Currency.find(:usd)
      end

      it "overrides default currency with the currency registered for the model" do
        @dummy_product2.price.currency.should == Money::Currency.find(:gbp)
      end

      it "overrides default and model currency with the row currency" do
        @dummy_product1.price.currency.should == Money::Currency.find(:usd)
      end

      it "constructs the money attribute from the stored mapped attribute values" do
        @transaction.amount.should == Money.new(2400, :usd)
      end

      it "instantiates correctly Money objects from the mapped attributes" do
        t = Transaction.new(:amount_cents => 2500, :currency => "CAD")
        t.amount.should == Money.new(2500, "CAD")
      end

      it "assigns correctly Money objects to the attribute" do
        @transaction.amount = Money.new(2500, :eur)
        @transaction.save.should be_true
        @transaction.amount.cents.should == Money.new(2500, :eur).cents
        @transaction.amount.currency_as_string.should == "EUR"
      end

      it "raises exception if a non Money object is assigned to the attribute" do
        expect { @transaction.amount = "not a Money object" }.to raise_error(ArgumentError)
        expect { @transaction.amount = 234 }.to raise_error(ArgumentError)
      end

    end
  end

  describe "register_currency" do
    it "attaches currency at model level" do
      Product.currency.should == Money::Currency.find(:usd)
      DummyProduct.currency.should == Money::Currency.find(:gbp)
    end
  end
end
