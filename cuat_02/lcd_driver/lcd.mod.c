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
	{ 0xf55bc851, "platform_driver_unregister" },
	{ 0x6091b333, "unregister_chrdev_region" },
	{ 0xf238fdf7, "cdev_del" },
	{ 0x3df0823f, "class_destroy" },
	{ 0xaf87d05c, "device_destroy" },
	{ 0xe89992a5, "__platform_driver_register" },
	{ 0x7c1318e3, "device_create" },
	{ 0xebdab104, "__class_create" },
	{ 0x8fe01c8, "cdev_add" },
	{ 0xcdd72f0f, "cdev_alloc" },
	{ 0xe3ec2f2b, "alloc_chrdev_region" },
	{ 0x328a05f1, "strncpy" },
	{ 0x59d5dc5f, "devm_gpiod_get" },
	{ 0xdb7305a1, "__stack_chk_fail" },
	{ 0x28cc25db, "arm_copy_from_user" },
	{ 0x5f754e5a, "memset" },
	{ 0x8f678b07, "__stack_chk_guard" },
	{ 0x8c11e17b, "gpiod_set_value" },
	{ 0x8e865d3c, "arm_delay_ops" },
	{ 0x7e68fee7, "gpiod_put" },
	{ 0x7c32d0f0, "printk" },
	{ 0x2e5810c6, "__aeabi_unwind_cpp_pr1" },
	{ 0xb1ad28e0, "__gnu_mcount_nc" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("of:N*T*Clcd");
MODULE_ALIAS("of:N*T*ClcdC*");
