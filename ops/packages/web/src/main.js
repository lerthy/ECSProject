// E-commerce Frontend Application
class ECommerceApp {
    constructor() {
        // API URL configuration - use CloudFront domain for HTTPS support
        this.baseURL = window.API_URL || 'https://d2twq0ejn0l6d2.cloudfront.net/api';
        this.currentUserId = 'user123'; // In production, this would come from authentication
        this.currentPage = 'products';
        this.cart = { items: [], total: 0 };
        this.products = [];
        this.orders = [];

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadProducts();
        this.loadCart();
        this.setupNavigation();
    }

    // Event Listeners
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = e.target.getAttribute('data-page');
                this.navigateToPage(page);
            });
        });

        // Filter products
        document.getElementById('apply-filters').addEventListener('click', () => {
            this.applyFilters();
        });

        // Category filter change
        document.getElementById('category-filter').addEventListener('change', () => {
            this.applyFilters();
        });

        // Checkout modal
        document.getElementById('checkout-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.processCheckout(e);
        });

        // Payment method change
        document.querySelector('select[name="paymentType"]').addEventListener('change', (e) => {
            this.togglePaymentFields(e.target.value);
        });

        // Modal close buttons
        document.querySelectorAll('.close').forEach(close => {
            close.addEventListener('click', (e) => {
                e.target.closest('.modal').classList.remove('active');
            });
        });

        // Cancel checkout
        document.getElementById('cancel-checkout').addEventListener('click', () => {
            document.getElementById('checkout-modal').classList.remove('active');
        });

        // Click outside modal to close
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    modal.classList.remove('active');
                }
            });
        });
    }

    setupNavigation() {
        // Handle page navigation buttons
        document.addEventListener('click', (e) => {
            if (e.target.hasAttribute('data-page')) {
                const page = e.target.getAttribute('data-page');
                this.navigateToPage(page);
            }
        });
    }

    navigateToPage(page) {
        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[data-page="${page}"]`).classList.add('active');

        // Show/hide pages
        document.querySelectorAll('.page').forEach(pageEl => {
            pageEl.classList.remove('active');
        });
        document.getElementById(`${page}-page`).classList.add('active');

        this.currentPage = page;

        // Load page data
        switch (page) {
            case 'products':
                this.loadProducts();
                break;
            case 'cart':
                this.loadCart();
                break;
            case 'orders':
                this.loadOrders();
                break;
        }
    }

    // API Methods
    async apiCall(endpoint, method = 'GET', data = null) {
        try {
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json',
                }
            };

            if (data) {
                options.body = JSON.stringify(data);
            }

            const response = await fetch(`${this.baseURL}${endpoint}`, options);
            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'API request failed');
            }

            return result;
        } catch (error) {
            console.error('API Error:', error);
            this.showToast(`Error: ${error.message}`, 'error');
            throw error;
        }
    }

    // Products
    async loadProducts() {
        const loading = document.getElementById('products-loading');
        const grid = document.getElementById('products-grid');

        loading.style.display = 'block';
        grid.innerHTML = '';

        try {
            const category = document.getElementById('category-filter').value;
            const minPrice = document.getElementById('min-price').value;
            const maxPrice = document.getElementById('max-price').value;

            let url = '/products?';
            if (category) url += `category=${category}&`;
            if (minPrice) url += `minPrice=${minPrice}&`;
            if (maxPrice) url += `maxPrice=${maxPrice}&`;

            const response = await this.apiCall(url.slice(0, -1));
            this.products = response.data;
            this.renderProducts(this.products);
        } catch (error) {
            grid.innerHTML = '<p>Failed to load products. Please try again.</p>';
        } finally {
            loading.style.display = 'none';
        }
    }

    renderProducts(products) {
        const grid = document.getElementById('products-grid');

        if (products.length === 0) {
            grid.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <h3>No products found</h3>
                    <p>Try adjusting your filters or search criteria.</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = products.map(product => `
            <div class="product-card" onclick="app.showProductDetail('${product.id}')">
                <div class="product-image">
                    <i class="fas fa-box"></i>
                </div>
                <div class="product-category">${product.category}</div>
                <div class="product-name">${product.name}</div>
                <div class="product-description">${product.description}</div>
                <div class="product-price">$${product.price.toFixed(2)}</div>
                <div class="product-stock ${product.stock < 10 ? 'stock-low' : ''}">
                    ${product.stock} in stock
                </div>
                <button class="btn btn-primary btn-small" 
                        onclick="event.stopPropagation(); app.addToCart('${product.id}', '${product.name}', ${product.price})">
                    <i class="fas fa-cart-plus"></i> Add to Cart
                </button>
            </div>
        `).join('');
    }

    showProductDetail(productId) {
        const product = this.products.find(p => p.id === productId);
        if (!product) return;

        const modal = document.getElementById('product-modal');
        const detail = document.getElementById('product-detail');

        detail.innerHTML = `
            <div class="product-detail-content">
                <div class="product-image" style="height: 300px; margin-bottom: 2rem;">
                    <i class="fas fa-box"></i>
                </div>
                <div class="product-category">${product.category}</div>
                <h2>${product.name}</h2>
                <p class="product-description">${product.description}</p>
                <div class="product-price">$${product.price.toFixed(2)}</div>
                <div class="product-stock ${product.stock < 10 ? 'stock-low' : ''}">
                    ${product.stock} in stock
                </div>
                <div style="margin-top: 2rem;">
                    <button class="btn btn-primary" 
                            onclick="app.addToCart('${product.id}', '${product.name}', ${product.price}); document.getElementById('product-modal').classList.remove('active');">
                        <i class="fas fa-cart-plus"></i> Add to Cart
                    </button>
                </div>
            </div>
        `;

        modal.classList.add('active');
    }

    applyFilters() {
        this.loadProducts();
    }

    // Cart Management
    async loadCart() {
        const loading = document.getElementById('cart-loading');
        const content = document.getElementById('cart-content');
        const empty = document.getElementById('empty-cart');

        loading.style.display = 'block';
        content.style.display = 'none';
        empty.style.display = 'none';

        try {
            const response = await this.apiCall(`/cart/${this.currentUserId}`);
            this.cart = response.data;

            if (this.cart.items.length === 0) {
                empty.style.display = 'block';
            } else {
                this.renderCart();
                content.style.display = 'grid';
            }

            this.updateCartCount();
        } catch (error) {
            empty.style.display = 'block';
        } finally {
            loading.style.display = 'none';
        }
    }

    renderCart() {
        const itemsContainer = document.getElementById('cart-items');
        const summaryContainer = document.getElementById('cart-summary');

        // Render cart items
        itemsContainer.innerHTML = this.cart.items.map(item => `
            <div class="cart-item">
                <div class="cart-item-image">
                    <i class="fas fa-box"></i>
                </div>
                <div class="cart-item-details">
                    <div class="cart-item-name">Product ${item.productId}</div>
                    <div class="cart-item-price">$${item.price.toFixed(2)}</div>
                    <div class="cart-item-controls">
                        <button class="btn btn-small btn-secondary" 
                                onclick="app.updateCartItemQuantity('${item.id}', ${item.quantity - 1})">
                            <i class="fas fa-minus"></i>
                        </button>
                        <input type="number" class="quantity-input" 
                               value="${item.quantity}" min="1"
                               onchange="app.updateCartItemQuantity('${item.id}', this.value)">
                        <button class="btn btn-small btn-secondary" 
                                onclick="app.updateCartItemQuantity('${item.id}', ${item.quantity + 1})">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-small btn-danger" 
                                onclick="app.removeFromCart('${item.id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `).join('');

        // Render cart summary
        summaryContainer.innerHTML = `
            <h3>Order Summary</h3>
            <div class="summary-row">
                <span>Subtotal:</span>
                <span>$${this.cart.subtotal?.toFixed(2) || '0.00'}</span>
            </div>
            <div class="summary-row">
                <span>Tax:</span>
                <span>$${this.cart.tax?.toFixed(2) || '0.00'}</span>
            </div>
            <div class="summary-row">
                <span>Shipping:</span>
                <span>${this.cart.subtotal > 50 ? 'FREE' : '$9.99'}</span>
            </div>
            <div class="summary-row total">
                <span>Total:</span>
                <span>$${this.cart.total?.toFixed(2) || '0.00'}</span>
            </div>
            <button class="btn btn-success" style="width: 100%; margin-top: 1rem;" 
                    onclick="app.showCheckoutModal()">
                <i class="fas fa-credit-card"></i> Proceed to Checkout
            </button>
        `;
    }

    async addToCart(productId, productName, price) {
        try {
            await this.apiCall(`/cart/${this.currentUserId}/items`, 'POST', {
                productId,
                quantity: 1,
                price
            });

            this.showToast(`${productName} added to cart!`, 'success');
            this.updateCartCount();

            if (this.currentPage === 'cart') {
                this.loadCart();
            }
        } catch (error) {
            this.showToast('Failed to add item to cart', 'error');
        }
    }

    async updateCartItemQuantity(itemId, quantity) {
        if (quantity < 1) {
            this.removeFromCart(itemId);
            return;
        }

        try {
            await this.apiCall(`/cart/${this.currentUserId}/items/${itemId}`, 'PUT', {
                quantity: parseInt(quantity)
            });

            this.loadCart();
        } catch (error) {
            this.showToast('Failed to update item quantity', 'error');
        }
    }

    async removeFromCart(itemId) {
        try {
            await this.apiCall(`/cart/${this.currentUserId}/items/${itemId}`, 'DELETE');
            this.showToast('Item removed from cart', 'info');
            this.loadCart();
        } catch (error) {
            this.showToast('Failed to remove item from cart', 'error');
        }
    }

    updateCartCount() {
        // Update cart count in navigation
        const cartCount = document.querySelector('.cart-count');
        const totalItems = this.cart.items?.reduce((sum, item) => sum + item.quantity, 0) || 0;
        cartCount.textContent = totalItems;
    }

    // Checkout
    showCheckoutModal() {
        if (this.cart.items.length === 0) {
            this.showToast('Your cart is empty', 'warning');
            return;
        }

        document.getElementById('checkout-modal').classList.add('active');
    }

    togglePaymentFields(paymentType) {
        const cardFields = document.getElementById('card-fields');
        const paypalFields = document.getElementById('paypal-fields');

        cardFields.style.display = 'none';
        paypalFields.style.display = 'none';

        if (paymentType === 'credit_card' || paymentType === 'debit_card') {
            cardFields.style.display = 'block';
        } else if (paymentType === 'paypal') {
            paypalFields.style.display = 'block';
        }
    }

    async processCheckout(event) {
        const formData = new FormData(event.target);
        const data = Object.fromEntries(formData);

        // Build checkout data
        const checkoutData = {
            shippingAddress: {
                street: data.street,
                city: data.city,
                state: data.state,
                zipCode: data.zipCode,
                country: data.country
            },
            paymentMethod: {
                type: data.paymentType
            }
        };

        // Add payment method specific fields
        if (data.paymentType === 'credit_card' || data.paymentType === 'debit_card') {
            checkoutData.paymentMethod.cardNumber = data.cardNumber;
            checkoutData.paymentMethod.expiryMonth = parseInt(data.expiryMonth);
            checkoutData.paymentMethod.expiryYear = parseInt(data.expiryYear);
            checkoutData.paymentMethod.cvv = data.cvv;
        } else if (data.paymentType === 'paypal') {
            checkoutData.paymentMethod.email = data.paypalEmail;
        }

        try {
            await this.apiCall(`/checkout/${this.currentUserId}`, 'POST', checkoutData);

            this.showToast('Order placed successfully!', 'success');
            document.getElementById('checkout-modal').classList.remove('active');

            // Clear cart and navigate to orders
            this.cart = { items: [], total: 0 };
            this.updateCartCount();
            this.navigateToPage('orders');

        } catch (error) {
            this.showToast('Checkout failed. Please try again.', 'error');
        }
    }

    // Orders
    async loadOrders() {
        const loading = document.getElementById('orders-loading');
        const list = document.getElementById('orders-list');
        const empty = document.getElementById('empty-orders');

        loading.style.display = 'block';
        list.innerHTML = '';
        empty.style.display = 'none';

        try {
            const response = await this.apiCall(`/orders/${this.currentUserId}`);
            this.orders = response.data;

            if (this.orders.length === 0) {
                empty.style.display = 'block';
            } else {
                this.renderOrders();
            }
        } catch (error) {
            empty.style.display = 'block';
        } finally {
            loading.style.display = 'none';
        }
    }

    renderOrders() {
        const list = document.getElementById('orders-list');

        list.innerHTML = this.orders.map(order => `
            <div class="order-card">
                <div class="order-header">
                    <div class="order-id">Order #${order.id.slice(0, 8)}</div>
                    <div class="order-status status-${order.status}">${order.status}</div>
                </div>
                <div class="order-items">
                    ${order.items.map(item => `
                        <div class="order-item">
                            <span>Product ${item.productId} × ${item.quantity}</span>
                            <span>$${(item.price * item.quantity).toFixed(2)}</span>
                        </div>
                    `).join('')}
                </div>
                <div class="order-total">Total: $${order.totals.total.toFixed(2)}</div>
                <div style="margin-top: 1rem; font-size: 0.9rem; color: #6c757d;">
                    Ordered on ${new Date(order.createdAt).toLocaleDateString()}
                </div>
            </div>
        `).join('');
    }

    // Utility Methods
    showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');

        const icons = {
            success: 'fas fa-check-circle',
            error: 'fas fa-exclamation-circle',
            warning: 'fas fa-exclamation-triangle',
            info: 'fas fa-info-circle'
        };

        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <i class="${icons[type]} toast-icon"></i>
            <span>${message}</span>
        `;

        container.appendChild(toast);

        // Auto remove after 5 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new ECommerceApp();
});

export default ECommerceApp;