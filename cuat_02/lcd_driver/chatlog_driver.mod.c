#include <linux/build-salt.h>
#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x516e49f9, "module_layout" },
	{ 0x3df0823f, "class_destroy" },
	{ 0xaf87d05c, "device_destroy" },
	{ 0xf55bc851, "platform_driver_unregister" },
	{ 0xe89992a5, "__platform_driver_register" },
	{ 0x7c1318e3, "device_create" },
	{ 0xf238fdf7, "cdev_del" },
	{ 0xebdab104, "__class_create" },
	{ 0x8fe01c8, "cdev_add" },
	{ 0x6091b333, "unregister_chrdev_region" },
	{ 0xcdd72f0f, "cdev_alloc" },
	{ 0xe3ec2f2b, "alloc_chrdev_region" },
	{ 0xd6b8e852, "request_threaded_irq" },
	{ 0xe9931696, "platform_get_irq" },
	{ 0xe97c4103, "ioremap" },
	{ 0x28cc25db, "arm_copy_from_user" },
	{ 0x5f754e5a, "memset" },
	{ 0x8e865d3c, "arm_delay_ops" },
	{ 0x3dcf1ffa, "__wake_up" },
	{ 0x822137e2, "arm_heavy_mb" },
	{ 0xc1514a3b, "free_irq" },
	{ 0xedc03953, "iounmap" },
	{ 0xdb7305a1, "__stack_chk_fail" },
	{ 0x49970de8, "finish_wait" },
	{ 0x647af474, "prepare_to_wait_event" },
	{ 0x1000e51, "schedule" },
	{ 0xfe487975, "init_wait_entry" },
	{ 0xf4fa543b, "arm_copy_to_user" },
	{ 0x97255bdf, "strlen" },
	{ 0x8f678b07, "__stack_chk_guard" },
	{ 0x7c32d0f0, "printk" },
	{ 0x2e5810c6, "__aeabi_unwind_cpp_pr1" },
	{ 0xb1ad28e0, "__gnu_mcount_nc" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("of:N*T*Ctd3_glecer");
MODULE_ALIAS("of:N*T*Ctd3_glecerC*");
