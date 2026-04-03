require "test_helper"

class WishlistItemTest < ActiveSupport::TestCase
  test "valid wishlist item" do
    item = build(:wishlist_item)
    assert item.valid?
  end

  test "requires name" do
    item = build(:wishlist_item, name: nil)
    assert_not item.valid?
  end

  test "requires priority" do
    item = build(:wishlist_item, priority: nil)
    assert_not item.valid?
  end

  test "requires status" do
    item = build(:wishlist_item, status: nil)
    assert_not item.valid?
  end

  test "validates currency inclusion" do
    item = build(:wishlist_item, currency: "INVALID")
    assert_not item.valid?
    assert_includes item.errors[:currency], "is not included in the list"
  end

  test "price must be non-negative" do
    item = build(:wishlist_item, price: -5)
    assert_not item.valid?
  end

  test "validates url format" do
    item = build(:wishlist_item, url: "https://example.com/product")
    assert item.valid?
  end

  test "rejects invalid url format" do
    item = build(:wishlist_item, url: "ftp://example.com/file")
    assert_not item.valid?
  end

  # URL normalization
  test "normalize_url strips query params and normalizes case" do
    assert_equal "https://example.com/product",
      WishlistItem.normalize_url("https://Example.COM/product?ref=123")
  end

  test "normalize_url removes trailing slash" do
    assert_equal "https://example.com/product",
      WishlistItem.normalize_url("https://example.com/product/")
  end

  test "normalize_url returns nil for blank input" do
    assert_nil WishlistItem.normalize_url(nil)
    assert_nil WishlistItem.normalize_url("")
  end

  # Formatted price
  test "formatted_price for USD" do
    item = build(:wishlist_item, price: 1234.56, currency: "USD")
    assert_equal "$1,234.56", item.formatted_price
  end

  test "formatted_price for BRL" do
    item = build(:wishlist_item, price: 1234.56, currency: "BRL")
    assert_equal "R$ 1.234,56", item.formatted_price
  end

  test "formatted_price for JPY has no decimals" do
    item = build(:wishlist_item, price: 15000, currency: "JPY")
    assert_equal "\u00A515,000", item.formatted_price
  end

  test "formatted_price for EUR" do
    item = build(:wishlist_item, price: 99.99, currency: "EUR")
    assert_equal "\u20AC99.99", item.formatted_price
  end

  test "formatted_price returns translation when price is nil" do
    item = build(:wishlist_item, price: nil)
    assert_equal "Price not set", item.formatted_price
  end

  # Safe URL
  test "safe_url returns url for http/https" do
    item = build(:wishlist_item, url: "https://example.com")
    assert_equal "https://example.com", item.safe_url
  end

  test "safe_url returns nil for javascript urls" do
    item = build(:wishlist_item)
    item.url = "javascript:alert(1)"
    assert_nil item.safe_url
  end

  test "safe_url returns nil for blank url" do
    item = build(:wishlist_item, url: nil)
    assert_nil item.safe_url
  end
end
