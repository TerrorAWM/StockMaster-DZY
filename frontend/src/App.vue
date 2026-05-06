<template>
  <div v-if="!session.token" class="login-screen">
    <el-card class="login-card">
      <h1>StockMaster</h1>
      <p>仓库库存云原生管理系统</p>
      <el-form label-position="top" @submit.prevent>
        <el-form-item label="用户名">
          <el-input v-model="loginForm.username" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="loginForm.password" type="password" show-password />
        </el-form-item>
        <el-button type="primary" class="full" @click="login"><i class="fa-solid fa-right-to-bracket"></i> 登录</el-button>
      </el-form>
    </el-card>
  </div>

  <el-container v-else class="shell">
    <el-aside width="224px">
      <div class="brand"><i class="fa-solid fa-boxes-stacked"></i> StockMaster</div>
      <el-menu :default-active="active" @select="active = $event">
        <el-menu-item index="dashboard"><i class="fa-solid fa-chart-line"></i><span>仪表盘</span></el-menu-item>
        <el-menu-item index="products"><i class="fa-solid fa-box"></i><span>商品管理</span></el-menu-item>
        <el-menu-item index="inbound"><i class="fa-solid fa-arrow-down"></i><span>入库</span></el-menu-item>
        <el-menu-item index="outbound"><i class="fa-solid fa-arrow-up"></i><span>出库</span></el-menu-item>
        <el-menu-item index="stock"><i class="fa-solid fa-warehouse"></i><span>库存查询</span></el-menu-item>
        <el-menu-item index="orders"><i class="fa-solid fa-list"></i><span>库存流水</span></el-menu-item>
        <el-menu-item index="warnings"><i class="fa-solid fa-triangle-exclamation"></i><span>库存预警</span></el-menu-item>
        <el-menu-item v-if="session.role === 'admin'" index="users"><i class="fa-solid fa-users-gear"></i><span>用户管理</span></el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header>
        <strong>{{ pageTitle }}</strong>
        <div>{{ session.username }} · {{ session.role }} <el-button link @click="logout">退出</el-button></div>
      </el-header>
      <el-main>
        <section v-if="active === 'dashboard'" class="grid">
          <el-card><strong>{{ products.length }}</strong><span>商品数量</span></el-card>
          <el-card><strong>{{ totalStock }}</strong><span>库存总量</span></el-card>
          <el-card><strong>{{ warnings.length }}</strong><span>预警数量</span></el-card>
        </section>

        <section v-if="active === 'products'">
          <el-button type="primary" @click="saveProduct"><i class="fa-solid fa-plus"></i> 新增商品</el-button>
          <el-form :inline="true" class="toolbar">
            <el-input v-model="productForm.sku" placeholder="SKU" />
            <el-input v-model="productForm.name" placeholder="商品名称" />
            <el-input v-model="productForm.category" placeholder="分类" />
            <el-input v-model="productForm.unit" placeholder="单位" />
            <el-input-number v-model="productForm.warningThreshold" :min="0" />
          </el-form>
          <el-table :data="products" border>
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="sku" label="SKU" />
            <el-table-column prop="name" label="商品名称" />
            <el-table-column prop="category" label="分类" />
            <el-table-column prop="unit" label="单位" width="90" />
            <el-table-column prop="warningThreshold" label="预警阈值" width="110" />
          </el-table>
        </section>

        <section v-if="active === 'inbound' || active === 'outbound'">
          <el-card class="form-card">
            <el-form label-width="90px">
              <el-form-item label="商品">
                <el-select v-model="orderForm.productId" placeholder="选择商品">
                  <el-option v-for="p in products" :key="p.id" :label="`${p.sku} - ${p.name}`" :value="p.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="数量">
                <el-input-number v-model="orderForm.quantity" :min="1" />
              </el-form-item>
              <el-form-item label="备注">
                <el-input v-model="orderForm.remark" />
              </el-form-item>
              <el-button type="primary" @click="submitOrder">{{ active === 'inbound' ? '确认入库' : '确认出库' }}</el-button>
            </el-form>
          </el-card>
        </section>

        <el-table v-if="active === 'stock'" :data="stock" border>
          <el-table-column prop="productId" label="商品ID" />
          <el-table-column prop="quantity" label="库存数量" />
        </el-table>

        <el-table v-if="active === 'orders'" :data="orders" border>
          <el-table-column prop="id" label="ID" width="80" />
          <el-table-column prop="productId" label="商品ID" />
          <el-table-column prop="type" label="类型" />
          <el-table-column prop="quantity" label="数量" />
          <el-table-column prop="operator" label="操作人" />
          <el-table-column prop="createdAt" label="时间" />
        </el-table>

        <el-table v-if="active === 'warnings'" :data="warnings" border>
          <el-table-column prop="productId" label="商品ID" />
          <el-table-column prop="quantity" label="当前库存" />
          <el-table-column prop="warningThreshold" label="预警阈值" />
        </el-table>

        <section v-if="active === 'users'">
          <el-form :inline="true" class="toolbar">
            <el-input v-model="userForm.username" placeholder="用户名" />
            <el-input v-model="userForm.password" placeholder="密码" />
            <el-select v-model="userForm.role">
              <el-option label="staff" value="staff" />
              <el-option label="admin" value="admin" />
            </el-select>
            <el-button type="primary" @click="createUser">创建用户</el-button>
          </el-form>
          <el-table :data="users" border>
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="username" label="用户名" />
            <el-table-column prop="role" label="角色" />
            <el-table-column prop="enabled" label="启用" />
          </el-table>
        </section>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import axios from 'axios'
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'

const api = axios.create({ baseURL: '/api' })
const session = reactive({ token: localStorage.getItem('token'), username: localStorage.getItem('username'), role: localStorage.getItem('role') })
api.interceptors.request.use(config => {
  if (session.token) config.headers.Authorization = `Bearer ${session.token}`
  return config
})

const active = ref('dashboard')
const loginForm = reactive({ username: 'admin', password: 'admin123' })
const productForm = reactive({ sku: '', name: '', category: '', unit: '件', warningThreshold: 10 })
const orderForm = reactive({ productId: null, quantity: 1, remark: '' })
const userForm = reactive({ username: '', password: '123456', role: 'staff' })
const products = ref([])
const stock = ref([])
const orders = ref([])
const warnings = ref([])
const users = ref([])

const pageTitle = computed(() => ({ dashboard: '仪表盘', products: '商品管理', inbound: '入库', outbound: '出库', stock: '库存查询', orders: '库存流水', warnings: '库存预警', users: '用户管理' }[active.value]))
const totalStock = computed(() => stock.value.reduce((sum, item) => sum + item.quantity, 0))

async function login() {
  const { data } = await api.post('/auth/login', loginForm)
  if (data.code !== 0) return ElMessage.error(data.message)
  Object.assign(session, data.data)
  localStorage.setItem('token', session.token)
  localStorage.setItem('username', session.username)
  localStorage.setItem('role', session.role)
  await loadAll()
}

function logout() {
  localStorage.clear()
  Object.assign(session, { token: null, username: null, role: null })
}

async function request(fn) {
  const { data } = await fn()
  if (data.code !== 0) throw new Error(data.message)
  return data.data
}

async function loadAll() {
  if (!session.token) return
  products.value = await request(() => api.get('/products'))
  stock.value = await request(() => api.get('/stock'))
  orders.value = await request(() => api.get('/orders'))
  warnings.value = await request(() => api.get('/stock/warnings'))
  if (session.role === 'admin') users.value = await request(() => api.get('/users'))
}

async function saveProduct() {
  try {
    await request(() => api.post('/products', productForm))
    ElMessage.success('商品已保存')
    Object.assign(productForm, { sku: '', name: '', category: '', unit: '件', warningThreshold: 10 })
    await loadAll()
  } catch (e) { ElMessage.error(e.message) }
}

async function submitOrder() {
  try {
    const url = active.value === 'inbound' ? '/orders/inbound' : '/orders/outbound'
    await request(() => api.post(url, orderForm))
    ElMessage.success('操作成功')
    await loadAll()
  } catch (e) { ElMessage.error(e.message) }
}

async function createUser() {
  try {
    await request(() => api.post('/users', userForm))
    ElMessage.success('用户已创建')
    await loadAll()
  } catch (e) { ElMessage.error(e.message) }
}

watch(active, loadAll)
loadAll()
</script>

