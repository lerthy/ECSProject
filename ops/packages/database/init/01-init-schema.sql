-- E-commerce Database Initialization Script
-- This script creates the basic schema for local development

-- Create tables for the e-commerce application
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500),
    category VARCHAR(100),
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'US',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address_id INTEGER REFERENCES addresses(id),
    billing_address_id INTEGER REFERENCES addresses(id),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cart_items (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_cart_session ON cart_items(session_id);

-- Insert sample data for development
INSERT INTO products (name, description, price, image_url, category, stock_quantity) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 'https://example.com/laptop.jpg', 'Electronics', 50),
('Wireless Headphones', 'Premium noise-cancelling headphones', 299.99, 'https://example.com/headphones.jpg', 'Electronics', 100),
('Coffee Mug', 'Ceramic coffee mug with ergonomic handle', 19.99, 'https://example.com/mug.jpg', 'Kitchen', 200),
('Running Shoes', 'Comfortable running shoes for all terrains', 129.99, 'https://example.com/shoes.jpg', 'Sports', 75),
('Book: JavaScript Guide', 'Complete guide to modern JavaScript development', 39.99, 'https://example.com/book.jpg', 'Books', 30),
('Smartphone', 'Latest smartphone with advanced camera', 899.99, 'https://example.com/phone.jpg', 'Electronics', 25),
('Water Bottle', 'Insulated stainless steel water bottle', 24.99, 'https://example.com/bottle.jpg', 'Sports', 150),
('Desk Chair', 'Ergonomic office chair with lumbar support', 349.99, 'https://example.com/chair.jpg', 'Furniture', 20)
ON CONFLICT DO NOTHING;

-- Insert sample customer for testing
INSERT INTO customers (email, first_name, last_name, phone) VALUES
('john.doe@example.com', 'John', 'Doe', '555-0123'),
('jane.smith@example.com', 'Jane', 'Smith', '555-0456')
ON CONFLICT (email) DO NOTHING;

-- Insert sample addresses
INSERT INTO addresses (customer_id, street_address, city, state, postal_code, is_default) VALUES
(1, '123 Main St', 'Anytown', 'CA', '12345', true),
(1, '456 Oak Ave', 'Another City', 'NY', '67890', false),
(2, '789 Pine St', 'Some City', 'TX', '54321', true)
ON CONFLICT DO NOTHING;

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ecommerce_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ecommerce_user;