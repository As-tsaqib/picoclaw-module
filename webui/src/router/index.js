import { createRouter, createWebHashHistory } from 'vue-router';
import OverviewView from '@/views/OverviewView.vue';

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'overview', component: OverviewView },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
});

export default router;
