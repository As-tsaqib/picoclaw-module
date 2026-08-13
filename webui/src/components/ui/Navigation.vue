<template>
  <nav ref="navEl"
    class="fixed bottom-0 left-0 right-0 w-full flex items-end bg-surface-container shadow-lg z-50 md:left-0 md:top-0 md:bottom-0 md:w-24 md:h-full md:flex-col backdrop-blur-md border-t border-surface-container-high"
    :style="{
      paddingBottom: 'var(--window-inset-bottom, 0px)',
      paddingRight: 'var(--window-inset-right, 0px)',
      paddingLeft: 'var(--window-inset-left, 0px)'
    }">
    <div class="w-full h-20 flex items-center justify-center md:h-full md:flex-col md:justify-center">
      <router-link v-for="item in navItems" :key="item.name" :to="item.path"
        class="flex-1 gap-1 w-full max-w-[200px] border-none bg-transparent text-sm flex justify-center items-center flex-col select-none p-0 no-underline transition-all duration-200 md:max-h-min md:py-3"
        :class="{
          'text-on-background': isActive(item),
          'text-on-surface-variant': !isActive(item),
        }">
        <div
          class="h-8 flex justify-center items-center rounded-full transition-all duration-200 ease-in-out"
          :class="{
            'bg-secondary-container px-5 text-on-secondary-container': isActive(item),
            'px-0': !isActive(item),
          }">
          <span class="text-lg">{{ item.icon }}</span>
        </div>
        <div class="text-[11px] mt-1">
          <span class="font-medium">{{ item.label }}</span>
        </div>
      </router-link>
    </div>
  </nav>
</template>

<script setup>
import { computed, ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const navItems = computed(() => [
  {
    name: 'Home',
    path: '/',
    label: 'Beranda',
    icon: '🏠',
  },
  {
    name: 'Settings',
    path: '/settings',
    label: 'Pengaturan',
    icon: '⚙️',
  },
])

const isActive = (item) => {
  const currentPath = route.path
  if (item.path === '/') return currentPath === '/'
  return currentPath.startsWith(item.path)
}

const navEl = ref(null)
let ro = null

onMounted(() => {
  ro = new ResizeObserver(([entry]) => {
    const h = entry.borderBoxSize?.[0]?.blockSize ?? entry.target.offsetHeight
    document.documentElement.style.setProperty('--nav-height', `${h}px`)
  })
  ro.observe(navEl.value)
})

onBeforeUnmount(() => ro?.disconnect())
</script>
