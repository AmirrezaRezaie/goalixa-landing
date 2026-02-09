// Helper function to get cookie value
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
}

// Check authentication and redirect
// Mobile menu toggle
document.addEventListener('DOMContentLoaded', function() {
    // Check for authentication cookie
    const authCookie = getCookie('goalixa_auth');

    // If authenticated, redirect to app
    if (authCookie && authCookie.length > 0) {
        window.location.href = 'https://app.goalixa.com';
        return;
    }

    const menuToggle = document.querySelector('.menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    const installBtn = document.getElementById('install-btn');
    
    if (menuToggle) {
        menuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            const icon = this.querySelector('i');
            if (navMenu.classList.contains('active')) {
                icon.classList.remove('fa-bars');
                icon.classList.add('fa-times');
            } else {
                icon.classList.remove('fa-times');
                icon.classList.add('fa-bars');
            }
        });
    }
    
    // Close menu when clicking outside
    document.addEventListener('click', function(event) {
        if (!event.target.closest('.navbar .container')) {
            navMenu.classList.remove('active');
            const icon = menuToggle.querySelector('i');
            icon.classList.remove('fa-times');
            icon.classList.add('fa-bars');
        }
    });
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                // Close mobile menu if open
                if (navMenu.classList.contains('active')) {
                    navMenu.classList.remove('active');
                    const icon = menuToggle.querySelector('i');
                    icon.classList.remove('fa-times');
                    icon.classList.add('fa-bars');
                }
                
                window.scrollTo({
                    top: targetElement.offsetTop - 80,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Add scroll effect to navbar
    window.addEventListener('scroll', function() {
        const navbar = document.querySelector('.navbar');
        if (window.scrollY > 20) {
            navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.08)';
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
        } else {
            navbar.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.05)';
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.85)';
        }
    });
    
    // Animate elements on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate');
            }
        });
    }, observerOptions);
    
    // Observe elements to animate
    document.querySelectorAll('.reveal').forEach(el => {
        observer.observe(el);
    });

    // PWA install prompt handling
    if (installBtn) {
        let deferredPrompt = null;
        const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true;

        const showInstall = () => installBtn.classList.add('visible');
        const hideInstall = () => installBtn.classList.remove('visible');

        if (isStandalone) {
            hideInstall();
        }

        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            deferredPrompt = e;
            showInstall();
        });

        installBtn.addEventListener('click', async () => {
            if (!deferredPrompt) return;
            deferredPrompt.prompt();
            await deferredPrompt.userChoice;
            deferredPrompt = null;
            hideInstall();
        });

        window.addEventListener('appinstalled', () => {
            deferredPrompt = null;
            hideInstall();
        });
    }
});

// Demo Mode Functions
let currentSlide = 1;
const totalSlides = 6;

function openDemoMode() {
    const modal = document.getElementById('demo-modal');
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
    currentSlide = 1;
    updateDemoSlide();
}

function closeDemoMode() {
    const modal = document.getElementById('demo-modal');
    modal.classList.remove('active');
    document.body.style.overflow = '';
}

function nextSlide() {
    if (currentSlide < totalSlides) {
        currentSlide++;
        updateDemoSlide();
    } else {
        closeDemoMode();
    }
}

function prevSlide() {
    if (currentSlide > 1) {
        currentSlide--;
        updateDemoSlide();
    }
}

function updateDemoSlide() {
    // Update slides
    const slides = document.querySelectorAll('.demo-slide');
    slides.forEach((slide, index) => {
        if (index + 1 === currentSlide) {
            slide.classList.add('active');
        } else {
            slide.classList.remove('active');
        }
    });

    // Update progress bar
    const progressBar = document.getElementById('demo-progress-bar');
    const progress = ((currentSlide - 1) / (totalSlides - 1)) * 100;
    progressBar.style.width = progress + '%';
    progressBar.style.background = 'linear-gradient(90deg, var(--primary), var(--primary-dark))';
}

// Close demo modal on Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeDemoMode();
    }
});

// Close demo modal when clicking outside
document.getElementById('demo-modal')?.addEventListener('click', function(event) {
    if (event.target === this || event.target.classList.contains('demo-modal-overlay')) {
        closeDemoMode();
    }
});
