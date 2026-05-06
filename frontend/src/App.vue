<template>
  <div v-if="!session.token" class="login-screen">
    <div class="card login-card shadow-sm">
      <div class="card-body p-4">
        <div class="brand-mark mb-3">
          <i class="fa-solid fa-boxes-stacked"></i>
        </div>
        <h1 class="h3 mb-1">StockMaster</h1>
        <p class="text-secondary mb-4">仓库库存云原生管理系统</p>
        <form @submit.prevent="login">
          <div class="mb-3">
            <label class="form-label">用户名</label>
            <input v-model.trim="loginForm.username" class="form-control" autocomplete="username" />
          </div>
          <div class="mb-4">
            <label class="form-label">密码</label>
            <input v-model="loginForm.password" class="form-control" type="password" autocomplete="current-password" />
          </div>
          <button class="btn btn-primary w-100" type="submit">
            <i class="fa-solid fa-right-to-bracket me-2"></i>登录
          </button>
        </form>
      </div>
    </div>
  </div>

  <div v-else class="app-shell">
    <aside class="sidebar">
      <div class="sidebar-brand">
        <i class="fa-solid fa-boxes-stacked"></i>
        <span>StockMaster</span>
      </div>
      <nav class="nav nav-pills flex-column gap-1">
        <button v-for="item in navItems" :key="item.key" class="nav-link" :class="{ active: active === item.key }" @click="active = item.key">
          <i :class="item.icon"></i>
          <span>{{ item.label }}</span>
        </button>
      </nav>
    </aside>

    <main class="content">
      <header class="topbar">
        <div>
          <h2>{{ pageTitle }}</h2>
          <p>{{ pageSubtitle }}</p>
        </div>
        <div class="user-chip">
          <span>{{ session.username }}</span>
          <span class="badge text-bg-light">{{ session.role }}</span>
          <button class="btn btn-outline-secondary btn-sm" @click="logout">
            <i class="fa-solid fa-arrow-right-from-bracket"></i>
          </button>
        </div>
      </header>

      <div v-if="notice.message" class="alert" :class="notice.type === 'success' ? 'alert-success' : 'alert-danger'" role="alert">
        {{ notice.message }}
      </div>

      <section v-if="active === 'dashboard'" class="dashboard">
        <div class="row g-3">
          <div class="col-12 col-md-4">
            <div class="metric-card">
              <span>商品数量</span>
              <strong>{{ products.length }}</strong>
              <i class="fa-solid fa-box"></i>
            </div>
          </div>
          <div class="col-12 col-md-4">
            <div class="metric-card">
              <span>库存总量</span>
              <strong>{{ totalStock }}</strong>
              <i class="fa-solid fa-warehouse"></i>
            </div>
          </div>
          <div class="col-12 col-md-4">
            <div class="metric-card">
              <span>预警数量</span>
              <strong>{{ warnings.length }}</strong>
              <i class="fa-solid fa-triangle-exclamation"></i>
            </div>
          </div>
        </div>
        <div class="panel mt-3">
          <div class="panel-heading">
            <div>
              <h3>库存分布</h3>
              <p>按商品统计当前库存数量</p>
            </div>
            <button class="btn btn-outline-primary btn-sm" @click="loadAll">
              <i class="fa-solid fa-rotate"></i>
            </button>
          </div>
          <div class="chart-wrap">
            <canvas ref="stockChartEl"></canvas>
          </div>
        </div>
      </section>

      <section v-if="active === 'products'" class="panel">
        <div class="panel-heading">
          <div>
            <h3>商品管理</h3>
            <p>维护商品基础信息，支持新增、查看、编辑、删除</p>
          </div>
          <button v-if="isAdmin" class="btn btn-primary" @click="openCreateProduct">
            <i class="fa-solid fa-plus me-2"></i>新增商品
          </button>
        </div>
        <div class="row g-2 mb-3">
          <div class="col-12 col-md-4">
            <div class="input-group">
              <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
              <input v-model.trim="productKeyword" class="form-control" placeholder="搜索 SKU / 名称 / 分类" />
            </div>
          </div>
          <div class="col-6 col-md-2">
            <select v-model="productStatusFilter" class="form-select">
              <option value="all">全部状态</option>
              <option value="enabled">启用</option>
              <option value="disabled">停用</option>
            </select>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead>
              <tr>
                <th>ID</th>
                <th>SKU</th>
                <th>商品名称</th>
                <th>分类</th>
                <th>单位</th>
                <th>预警阈值</th>
                <th>状态</th>
                <th class="text-end">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="product in filteredProducts" :key="product.id">
                <td>{{ product.id }}</td>
                <td><code>{{ product.sku }}</code></td>
                <td>{{ product.name }}</td>
                <td>{{ product.category || '-' }}</td>
                <td>{{ product.unit || '-' }}</td>
                <td>{{ product.warningThreshold }}</td>
                <td>
                  <span class="badge" :class="product.enabled ? 'text-bg-success' : 'text-bg-secondary'">
                    {{ product.enabled ? '启用' : '停用' }}
                  </span>
                </td>
                <td class="text-end">
                  <div class="btn-group btn-group-sm">
                    <button class="btn btn-outline-primary" @click="openProductDetail(product)" title="查看">
                      <i class="fa-solid fa-eye"></i>
                    </button>
                    <button v-if="isAdmin" class="btn btn-outline-secondary" @click="openEditProduct(product)" title="编辑">
                      <i class="fa-solid fa-pen"></i>
                    </button>
                    <button v-if="isAdmin" class="btn btn-outline-danger" @click="deleteProduct(product)" title="删除">
                      <i class="fa-solid fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredProducts.length === 0">
                <td colspan="8" class="empty-row">暂无商品</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="active === 'inbound' || active === 'outbound'" class="panel form-panel">
        <div class="panel-heading">
          <div>
            <h3>{{ active === 'inbound' ? '入库登记' : '出库登记' }}</h3>
            <p>{{ active === 'inbound' ? '增加指定商品库存' : '扣减指定商品库存' }}</p>
          </div>
        </div>
        <form class="row g-3" @submit.prevent="submitOrder">
          <div class="col-12 col-lg-6">
            <label class="form-label">商品</label>
            <select v-model.number="orderForm.productId" class="form-select" required>
              <option :value="null" disabled>选择商品</option>
              <option v-for="p in enabledProducts" :key="p.id" :value="p.id">{{ p.sku }} - {{ p.name }}</option>
            </select>
          </div>
          <div class="col-12 col-lg-3">
            <label class="form-label">数量</label>
            <input v-model.number="orderForm.quantity" class="form-control" type="number" min="1" required />
          </div>
          <div class="col-12">
            <label class="form-label">备注</label>
            <input v-model.trim="orderForm.remark" class="form-control" placeholder="可填写批次、用途或说明" />
          </div>
          <div class="col-12">
            <button class="btn btn-primary" type="submit">
              <i :class="active === 'inbound' ? 'fa-solid fa-arrow-down me-2' : 'fa-solid fa-arrow-up me-2'"></i>
              {{ active === 'inbound' ? '确认入库' : '确认出库' }}
            </button>
          </div>
        </form>
      </section>

      <section v-if="active === 'stock'" class="panel">
        <div class="panel-heading">
          <div>
            <h3>库存查询</h3>
            <p>查看每个商品的实时库存</p>
          </div>
          <button class="btn btn-outline-primary btn-sm" @click="loadAll"><i class="fa-solid fa-rotate"></i></button>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead><tr><th>商品ID</th><th>SKU</th><th>商品名称</th><th>库存数量</th><th>预警阈值</th></tr></thead>
            <tbody>
              <tr v-for="item in stockRows" :key="item.productId">
                <td>{{ item.productId }}</td>
                <td><code>{{ item.sku || '-' }}</code></td>
                <td>{{ item.name || '-' }}</td>
                <td>{{ item.quantity }}</td>
                <td>{{ item.warningThreshold ?? '-' }}</td>
              </tr>
              <tr v-if="stockRows.length === 0"><td colspan="5" class="empty-row">暂无库存</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="active === 'orders'" class="panel">
        <div class="panel-heading">
          <div>
            <h3>库存流水</h3>
            <p>记录所有入库和出库操作</p>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead><tr><th>ID</th><th>商品</th><th>类型</th><th>数量</th><th>操作人</th><th>备注</th><th>时间</th></tr></thead>
            <tbody>
              <tr v-for="order in orders" :key="order.id">
                <td>{{ order.id }}</td>
                <td>{{ productName(order.productId) }}</td>
                <td><span class="badge" :class="order.type === 'INBOUND' ? 'text-bg-primary' : 'text-bg-warning'">{{ order.type === 'INBOUND' ? '入库' : '出库' }}</span></td>
                <td>{{ order.quantity }}</td>
                <td>{{ order.operator }}</td>
                <td>{{ order.remark || '-' }}</td>
                <td>{{ formatTime(order.createdAt) }}</td>
              </tr>
              <tr v-if="orders.length === 0"><td colspan="7" class="empty-row">暂无流水</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="active === 'warnings'" class="panel">
        <div class="panel-heading">
          <div>
            <h3>库存预警</h3>
            <p>库存低于阈值的商品会显示在这里</p>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead><tr><th>商品ID</th><th>商品名称</th><th>当前库存</th><th>预警阈值</th></tr></thead>
            <tbody>
              <tr v-for="warning in warningRows" :key="warning.productId">
                <td>{{ warning.productId }}</td>
                <td>{{ warning.name || '-' }}</td>
                <td><span class="badge text-bg-danger">{{ warning.quantity }}</span></td>
                <td>{{ warning.warningThreshold }}</td>
              </tr>
              <tr v-if="warningRows.length === 0"><td colspan="4" class="empty-row">当前没有库存预警</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="active === 'users' && isAdmin" class="panel">
        <div class="panel-heading">
          <div>
            <h3>用户管理</h3>
            <p>创建用户并维护账号启用状态</p>
          </div>
        </div>
        <form class="row g-2 mb-3" @submit.prevent="createUser">
          <div class="col-12 col-md-3"><input v-model.trim="userForm.username" class="form-control" placeholder="用户名" required /></div>
          <div class="col-12 col-md-3"><input v-model="userForm.password" class="form-control" placeholder="密码" required /></div>
          <div class="col-12 col-md-2">
            <select v-model="userForm.role" class="form-select">
              <option value="staff">staff</option>
              <option value="admin">admin</option>
            </select>
          </div>
          <div class="col-12 col-md-2"><button class="btn btn-primary w-100" type="submit">创建用户</button></div>
        </form>
        <div class="table-responsive">
          <table class="table table-hover align-middle">
            <thead><tr><th>ID</th><th>用户名</th><th>角色</th><th>启用</th><th class="text-end">操作</th></tr></thead>
            <tbody>
              <tr v-for="user in users" :key="user.id">
                <td>{{ user.id }}</td>
                <td>{{ user.username }}</td>
                <td><span class="badge text-bg-light">{{ user.role }}</span></td>
                <td>{{ user.enabled ? '是' : '否' }}</td>
                <td class="text-end">
                  <button class="btn btn-outline-secondary btn-sm" :disabled="user.username === session.username" @click="toggleUser(user)">
                    {{ user.enabled ? '停用' : '启用' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>

    <div v-if="productModal.open" class="modal fade show modal-backdrop-view" tabindex="-1" role="dialog">
      <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">{{ productModal.mode === 'detail' ? '商品详情' : productModal.mode === 'edit' ? '编辑商品' : '新增商品' }}</h5>
            <button type="button" class="btn-close" @click="closeProductModal"></button>
          </div>
          <div class="modal-body">
            <dl v-if="productModal.mode === 'detail'" class="row detail-list">
              <dt class="col-sm-3">ID</dt><dd class="col-sm-9">{{ selectedProduct.id }}</dd>
              <dt class="col-sm-3">SKU</dt><dd class="col-sm-9"><code>{{ selectedProduct.sku }}</code></dd>
              <dt class="col-sm-3">商品名称</dt><dd class="col-sm-9">{{ selectedProduct.name }}</dd>
              <dt class="col-sm-3">分类</dt><dd class="col-sm-9">{{ selectedProduct.category || '-' }}</dd>
              <dt class="col-sm-3">单位</dt><dd class="col-sm-9">{{ selectedProduct.unit || '-' }}</dd>
              <dt class="col-sm-3">预警阈值</dt><dd class="col-sm-9">{{ selectedProduct.warningThreshold }}</dd>
              <dt class="col-sm-3">状态</dt><dd class="col-sm-9">{{ selectedProduct.enabled ? '启用' : '停用' }}</dd>
              <dt class="col-sm-3">当前库存</dt><dd class="col-sm-9">{{ stockQuantity(selectedProduct.id) }}</dd>
            </dl>
            <form v-else class="row g-3" @submit.prevent="saveProduct">
              <div class="col-12 col-md-6">
                <label class="form-label">SKU</label>
                <input v-model.trim="productForm.sku" class="form-control" :disabled="productModal.mode === 'edit'" required />
              </div>
              <div class="col-12 col-md-6">
                <label class="form-label">商品名称</label>
                <input v-model.trim="productForm.name" class="form-control" required />
              </div>
              <div class="col-12 col-md-6">
                <label class="form-label">分类</label>
                <input v-model.trim="productForm.category" class="form-control" />
              </div>
              <div class="col-12 col-md-3">
                <label class="form-label">单位</label>
                <input v-model.trim="productForm.unit" class="form-control" />
              </div>
              <div class="col-12 col-md-3">
                <label class="form-label">预警阈值</label>
                <input v-model.number="productForm.warningThreshold" class="form-control" type="number" min="0" />
              </div>
              <div class="col-12">
                <div class="form-check form-switch">
                  <input id="productEnabled" v-model="productForm.enabled" class="form-check-input" type="checkbox" />
                  <label class="form-check-label" for="productEnabled">启用商品</label>
                </div>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary" @click="closeProductModal">关闭</button>
            <button v-if="productModal.mode !== 'detail'" class="btn btn-primary" @click="saveProduct">保存</button>
          </div>
        </div>
      </div>
    </div>
    <div v-if="productModal.open" class="modal-backdrop fade show"></div>
  </div>
</template>

<script setup>
import axios from 'axios'
import { Chart, BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend } from 'chart.js'
import { computed, nextTick, onBeforeUnmount, reactive, ref, watch } from 'vue'

Chart.register(BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend)

const api = axios.create({ baseURL: '/api' })
const session = reactive({
  token: localStorage.getItem('token'),
  username: localStorage.getItem('username'),
  role: localStorage.getItem('role')
})

api.interceptors.request.use(config => {
  if (session.token) config.headers.Authorization = `Bearer ${session.token}`
  return config
})

const active = ref('dashboard')
const stockChartEl = ref(null)
let stockChart = null

const loginForm = reactive({ username: 'admin', password: 'admin123' })
const productForm = reactive({ id: null, sku: '', name: '', category: '', unit: '件', warningThreshold: 10, enabled: true })
const productModal = reactive({ open: false, mode: 'detail' })
const selectedProduct = ref({})
const productKeyword = ref('')
const productStatusFilter = ref('all')
const orderForm = reactive({ productId: null, quantity: 1, remark: '' })
const userForm = reactive({ username: '', password: '123456', role: 'staff' })
const notice = reactive({ type: 'success', message: '' })

const products = ref([])
const stock = ref([])
const orders = ref([])
const warnings = ref([])
const users = ref([])

const isAdmin = computed(() => session.role === 'admin')
const navItems = computed(() => [
  { key: 'dashboard', label: '仪表盘', icon: 'fa-solid fa-chart-line' },
  { key: 'products', label: '商品管理', icon: 'fa-solid fa-box' },
  { key: 'inbound', label: '入库', icon: 'fa-solid fa-arrow-down' },
  { key: 'outbound', label: '出库', icon: 'fa-solid fa-arrow-up' },
  { key: 'stock', label: '库存查询', icon: 'fa-solid fa-warehouse' },
  { key: 'orders', label: '库存流水', icon: 'fa-solid fa-list' },
  { key: 'warnings', label: '库存预警', icon: 'fa-solid fa-triangle-exclamation' },
  ...(isAdmin.value ? [{ key: 'users', label: '用户管理', icon: 'fa-solid fa-users-gear' }] : [])
])
const pageTitle = computed(() => navItems.value.find(item => item.key === active.value)?.label || '仪表盘')
const pageSubtitle = computed(() => ({
  dashboard: '查看库存核心指标和图形统计',
  products: '维护商品资料并查看商品详情',
  inbound: '登记商品入库',
  outbound: '登记商品出库',
  stock: '查询当前库存',
  orders: '追踪库存变动流水',
  warnings: '关注低库存商品',
  users: '维护系统用户'
}[active.value]))
const totalStock = computed(() => stock.value.reduce((sum, item) => sum + Number(item.quantity || 0), 0))
const productMap = computed(() => new Map(products.value.map(item => [item.id, item])))
const enabledProducts = computed(() => products.value.filter(item => item.enabled))
const filteredProducts = computed(() => {
  const keyword = productKeyword.value.toLowerCase()
  return products.value.filter(item => {
    const matchesKeyword = !keyword || [item.sku, item.name, item.category].some(value => String(value || '').toLowerCase().includes(keyword))
    const matchesStatus = productStatusFilter.value === 'all'
      || (productStatusFilter.value === 'enabled' && item.enabled)
      || (productStatusFilter.value === 'disabled' && !item.enabled)
    return matchesKeyword && matchesStatus
  })
})
const stockRows = computed(() => stock.value.map(item => ({ ...item, ...(productMap.value.get(item.productId) || {}) })))
const warningRows = computed(() => warnings.value.map(item => ({ ...item, ...(productMap.value.get(item.productId) || {}) })))

async function login() {
  try {
    const { data } = await api.post('/auth/login', loginForm)
    if (data.code !== 0) throw new Error(data.message)
    Object.assign(session, data.data)
    localStorage.setItem('token', session.token)
    localStorage.setItem('username', session.username)
    localStorage.setItem('role', session.role)
    showNotice('success', '登录成功')
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '登录失败')
  }
}

function logout() {
  localStorage.clear()
  Object.assign(session, { token: null, username: null, role: null })
  destroyChart()
}

async function request(fn) {
  const { data } = await fn()
  if (data.code !== 0) throw new Error(data.message)
  return data.data
}

async function loadAll() {
  if (!session.token) return
  try {
    products.value = await request(() => api.get('/products'))
    stock.value = await request(() => api.get('/stock'))
    orders.value = await request(() => api.get('/orders'))
    warnings.value = await request(() => api.get('/stock/warnings'))
    if (isAdmin.value) users.value = await request(() => api.get('/users'))
    await renderChart()
  } catch (error) {
    showNotice('danger', error.message || '数据加载失败')
  }
}

function resetProductForm() {
  Object.assign(productForm, { id: null, sku: '', name: '', category: '', unit: '件', warningThreshold: 10, enabled: true })
}

function openCreateProduct() {
  resetProductForm()
  productModal.mode = 'create'
  productModal.open = true
}

function openEditProduct(product) {
  Object.assign(productForm, { ...product })
  productModal.mode = 'edit'
  productModal.open = true
}

function openProductDetail(product) {
  selectedProduct.value = product
  productModal.mode = 'detail'
  productModal.open = true
}

function closeProductModal() {
  productModal.open = false
}

async function saveProduct() {
  try {
    if (productModal.mode === 'edit') {
      await request(() => api.put(`/products/${productForm.id}`, productForm))
      showNotice('success', '商品已更新')
    } else {
      await request(() => api.post('/products', productForm))
      showNotice('success', '商品已创建')
    }
    closeProductModal()
    resetProductForm()
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '商品保存失败')
  }
}

async function deleteProduct(product) {
  if (!window.confirm(`确认删除商品「${product.name}」吗？`)) return
  try {
    await request(() => api.delete(`/products/${product.id}`))
    showNotice('success', '商品已删除')
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '商品删除失败')
  }
}

async function submitOrder() {
  try {
    const url = active.value === 'inbound' ? '/orders/inbound' : '/orders/outbound'
    await request(() => api.post(url, orderForm))
    showNotice('success', active.value === 'inbound' ? '入库成功' : '出库成功')
    Object.assign(orderForm, { productId: null, quantity: 1, remark: '' })
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '操作失败')
  }
}

async function createUser() {
  try {
    await request(() => api.post('/users', userForm))
    showNotice('success', '用户已创建')
    Object.assign(userForm, { username: '', password: '123456', role: 'staff' })
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '用户创建失败')
  }
}

async function toggleUser(user) {
  try {
    await request(() => api.patch(`/users/${user.id}/status`, { enabled: !user.enabled }))
    showNotice('success', '用户状态已更新')
    await loadAll()
  } catch (error) {
    showNotice('danger', error.message || '用户状态更新失败')
  }
}

function productName(productId) {
  const product = productMap.value.get(productId)
  return product ? `${product.sku} - ${product.name}` : `商品 ${productId}`
}

function stockQuantity(productId) {
  return stock.value.find(item => item.productId === productId)?.quantity ?? 0
}

function formatTime(value) {
  if (!value) return '-'
  return String(value).replace('T', ' ').slice(0, 19)
}

function showNotice(type, message) {
  notice.type = type
  notice.message = message
  window.setTimeout(() => {
    if (notice.message === message) notice.message = ''
  }, 2800)
}

async function renderChart() {
  if (active.value !== 'dashboard') return
  await nextTick()
  if (!stockChartEl.value) return
  const labels = stockRows.value.map(item => item.name || `商品 ${item.productId}`)
  const values = stockRows.value.map(item => item.quantity)
  destroyChart()
  stockChart = new Chart(stockChartEl.value, {
    type: 'bar',
    data: {
      labels: labels.length ? labels : ['暂无库存'],
      datasets: [{
        label: '库存数量',
        data: values.length ? values : [0],
        backgroundColor: '#2563eb',
        borderRadius: 6
      }]
    },
    options: {
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
    }
  })
}

function destroyChart() {
  if (stockChart) {
    stockChart.destroy()
    stockChart = null
  }
}

watch(active, async () => {
  await loadAll()
})

watch([products, stock], renderChart, { deep: true })
onBeforeUnmount(destroyChart)
loadAll()
</script>
