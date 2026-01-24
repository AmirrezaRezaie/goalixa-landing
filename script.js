// Mobile menu toggle
document.addEventListener('DOMContentLoaded', function() {
    const menuToggle = document.querySelector('.menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
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
        if (window.scrollY > 50) {
            navbar.style.boxShadow = '0 5px 20px rgba(0, 0, 0, 0.1)';
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.98)';
        } else {
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.05)';
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
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
    
    // Simple animation for stats counter
    const stats = document.querySelectorAll('.stat h3');
    if (stats.length > 0) {
        const animateValue = (element, start, end, duration, formatter) => {
            let startTimestamp = null;
            const step = (timestamp) => {
                if (!startTimestamp) startTimestamp = timestamp;
                const progress = Math.min((timestamp - startTimestamp) / duration, 1);
                const value = Math.floor(progress * (end - start) + start);
                element.textContent = formatter(value);
                if (progress < 1) {
                    window.requestAnimationFrame(step);
                }
            };
            window.requestAnimationFrame(step);
        };
        
        // Trigger animation when stats are in view
        const statsObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const stat = entry.target;
                    const raw = stat.textContent.trim();
                    const hasPlus = raw.includes('+');
                    const suffixMatch = raw.match(/[KM]/);
                    const suffix = suffixMatch ? suffixMatch[0] : '';
                    const decimalsMatch = raw.match(/\.(\d+)/);
                    const decimals = decimalsMatch ? decimalsMatch[1].length : 0;
                    const baseValue = parseFloat(raw);
                    let value = baseValue;
                    if (suffix === 'K') {
                        value = baseValue * 1000;
                    } else if (suffix === 'M') {
                        value = baseValue * 1000000;
                    }
                    const formatter = (current) => {
                        if (suffix) {
                            const divisor = suffix === 'K' ? 1000 : 1000000;
                            const displayValue = current / divisor;
                            const formatted = decimals > 0 ? displayValue.toFixed(decimals) : Math.floor(displayValue);
                            return formatted + suffix + (hasPlus ? '+' : '');
                        }
                        return Math.floor(current) + (hasPlus ? '+' : '');
                    };
                    if (!stat.classList.contains('animated')) {
                        stat.classList.add('animated');
                        animateValue(stat, 0, value, 2000, formatter);
                    }
                }
            });
        }, { threshold: 0.5 });
        
        stats.forEach(stat => statsObserver.observe(stat));
    }
});
