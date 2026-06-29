<?php
/**
 * Plugin Name: Product Specs API
 * Description: API امن برای اپلیکیشن ثبت مشخصات فنی محصولات ووکامرس. مشخصات را فقط به‌عنوان ویژگی اختصاصی همان محصول ذخیره می‌کند و هیچ Global Attribute یا pa_ taxonomy نمی‌سازد.
 * Version: 1.0.0
 * Author: Product Specs
 * Requires PHP: 7.4
 * Requires at least: 5.8
 */

if (!defined('ABSPATH')) {
    exit;
}

if (!class_exists('PS_Product_Specs_API')) {
    class PS_Product_Specs_API {
        const OPTION_TOKEN = 'ps_specs_api_token';
        const REST_NS = 'product-specs/v1';

        public function __construct() {
            add_action('rest_api_init', array($this, 'register_routes'));
            add_action('admin_menu', array($this, 'admin_menu'));
            add_action('admin_init', array($this, 'handle_admin_actions'));
        }

        public static function activate() {
            if (!get_option(self::OPTION_TOKEN)) {
                update_option(self::OPTION_TOKEN, self::generate_token(), false);
            }
        }

        public static function generate_token() {
            if (function_exists('wp_generate_password')) {
                return wp_generate_password(48, false, false);
            }
            return bin2hex(random_bytes(24));
        }

        public function admin_menu() {
            add_options_page(
                'API مشخصات محصول',
                'API مشخصات محصول',
                'manage_options',
                'product-specs-api',
                array($this, 'settings_page')
            );
        }

        public function handle_admin_actions() {
            if (!is_admin() || !current_user_can('manage_options')) {
                return;
            }
            if (!isset($_POST['ps_specs_action'])) {
                return;
            }
            check_admin_referer('ps_specs_settings');

            $action = sanitize_text_field(wp_unslash($_POST['ps_specs_action']));
            if ($action === 'save_token') {
                $token = isset($_POST['ps_specs_api_token']) ? sanitize_text_field(wp_unslash($_POST['ps_specs_api_token'])) : '';
                if ($token !== '') {
                    update_option(self::OPTION_TOKEN, $token, false);
                }
                add_settings_error('ps_specs_api', 'saved', 'توکن ذخیره شد.', 'updated');
            }
            if ($action === 'regenerate_token') {
                update_option(self::OPTION_TOKEN, self::generate_token(), false);
                add_settings_error('ps_specs_api', 'regenerated', 'توکن جدید ساخته شد.', 'updated');
            }
        }

        public function settings_page() {
            if (!current_user_can('manage_options')) {
                return;
            }
            settings_errors('ps_specs_api');
            $token = get_option(self::OPTION_TOKEN, '');
            ?>
            <div class="wrap" dir="rtl">
                <h1>API مشخصات محصول</h1>
                <p>این افزونه برای اتصال اپلیکیشن موبایل به ووکامرس است.</p>
                <p><strong>نکته مهم:</strong> هوش مصنوعی در این نسخه داخل اپلیکیشن اجرا می‌شود. این افزونه فقط محصولات را می‌خواند و مشخصات نهایی را به‌عنوان ویژگی اختصاصی همان محصول ذخیره می‌کند.</p>

                <form method="post">
                    <?php wp_nonce_field('ps_specs_settings'); ?>
                    <input type="hidden" name="ps_specs_action" value="save_token">
                    <table class="form-table" role="presentation">
                        <tr>
                            <th scope="row"><label for="ps_specs_api_token">توکن اتصال اپلیکیشن</label></th>
                            <td>
                                <input type="text" id="ps_specs_api_token" name="ps_specs_api_token" value="<?php echo esc_attr($token); ?>" class="regular-text ltr" style="direction:ltr;width:480px;max-width:100%;">
                                <p class="description">این توکن را داخل اپلیکیشن در بخش تنظیمات وارد کنید.</p>
                            </td>
                        </tr>
                    </table>
                    <?php submit_button('ذخیره توکن'); ?>
                </form>

                <form method="post" style="margin-top:12px;">
                    <?php wp_nonce_field('ps_specs_settings'); ?>
                    <input type="hidden" name="ps_specs_action" value="regenerate_token">
                    <?php submit_button('ساخت توکن جدید', 'secondary'); ?>
                </form>

                <hr>
                <h2>آدرس‌های API</h2>
                <pre style="background:#fff;padding:16px;border:1px solid #ddd;direction:ltr;text-align:left;white-space:pre-wrap;">GET  <?php echo esc_url_raw(rest_url(self::REST_NS . '/ping')); ?>
GET  <?php echo esc_url_raw(rest_url(self::REST_NS . '/categories')); ?>
GET  <?php echo esc_url_raw(rest_url(self::REST_NS . '/products?category_id=12')); ?>
GET  <?php echo esc_url_raw(rest_url(self::REST_NS . '/products/123')); ?>
POST <?php echo esc_url_raw(rest_url(self::REST_NS . '/products/123/specs')); ?></pre>
                <p>در همه درخواست‌ها هدر زیر باید ارسال شود:</p>
                <pre style="background:#fff;padding:16px;border:1px solid #ddd;direction:ltr;text-align:left;">Authorization: Bearer YOUR_TOKEN</pre>
            </div>
            <?php
        }

        public function register_routes() {
            register_rest_route(self::REST_NS, '/ping', array(
                'methods' => 'GET',
                'callback' => array($this, 'ping'),
                'permission_callback' => array($this, 'check_permission'),
            ));

            register_rest_route(self::REST_NS, '/categories', array(
                'methods' => 'GET',
                'callback' => array($this, 'categories'),
                'permission_callback' => array($this, 'check_permission'),
            ));

            register_rest_route(self::REST_NS, '/products', array(
                'methods' => 'GET',
                'callback' => array($this, 'products'),
                'permission_callback' => array($this, 'check_permission'),
            ));

            register_rest_route(self::REST_NS, '/products/(?P<id>\d+)', array(
                'methods' => 'GET',
                'callback' => array($this, 'product_detail'),
                'permission_callback' => array($this, 'check_permission'),
                'args' => array(
                    'id' => array('validate_callback' => function($param) { return is_numeric($param); }),
                ),
            ));

            register_rest_route(self::REST_NS, '/products/(?P<id>\d+)/specs', array(
                'methods' => 'POST',
                'callback' => array($this, 'save_specs'),
                'permission_callback' => array($this, 'check_permission'),
                'args' => array(
                    'id' => array('validate_callback' => function($param) { return is_numeric($param); }),
                ),
            ));
        }

        public function check_permission(WP_REST_Request $request) {
            $saved = (string) get_option(self::OPTION_TOKEN, '');
            if ($saved === '') {
                return new WP_Error('ps_token_missing', 'توکن افزونه تنظیم نشده است.', array('status' => 403));
            }

            $auth = $request->get_header('authorization');
            $token = '';
            if ($auth && stripos($auth, 'bearer ') === 0) {
                $token = trim(substr($auth, 7));
            }
            if ($token === '') {
                $token = (string) $request->get_header('x-product-specs-token');
            }

            if (!hash_equals($saved, $token)) {
                return new WP_Error('ps_invalid_token', 'توکن اتصال اشتباه است.', array('status' => 401));
            }
            if (!class_exists('WooCommerce')) {
                return new WP_Error('ps_woo_missing', 'ووکامرس فعال نیست.', array('status' => 500));
            }
            return true;
        }

        public function ping() {
            return rest_ensure_response(array(
                'success' => true,
                'message' => 'اتصال موفق است',
                'site' => get_bloginfo('name'),
                'php' => PHP_VERSION,
            ));
        }

        public function categories() {
            $terms = get_terms(array(
                'taxonomy' => 'product_cat',
                'hide_empty' => false,
                'orderby' => 'name',
                'order' => 'ASC',
            ));

            if (is_wp_error($terms)) {
                return new WP_Error('ps_categories_error', $terms->get_error_message(), array('status' => 500));
            }

            $items = array();
            foreach ($terms as $term) {
                $thumb_id = (int) get_term_meta($term->term_id, 'thumbnail_id', true);
                $image = $thumb_id ? wp_get_attachment_image_url($thumb_id, 'medium') : '';
                $items[] = array(
                    'id' => (int) $term->term_id,
                    'name' => $term->name,
                    'count' => (int) $term->count,
                    'image' => $image ? $image : '',
                );
            }

            return rest_ensure_response(array('success' => true, 'items' => $items));
        }

        public function products(WP_REST_Request $request) {
            $category_id = absint($request->get_param('category_id'));
            $search = sanitize_text_field((string) $request->get_param('search'));
            $sort = sanitize_text_field((string) $request->get_param('sort'));
            $page = max(1, absint($request->get_param('page')));
            $per_page = min(50, max(1, absint($request->get_param('per_page'))));
            if (!$per_page) {
                $per_page = 30;
            }

            $args = array(
                'post_type' => 'product',
                'post_status' => 'publish',
                'posts_per_page' => $per_page,
                'paged' => $page,
                's' => $search,
            );

            if ($category_id) {
                $args['tax_query'] = array(
                    array(
                        'taxonomy' => 'product_cat',
                        'field' => 'term_id',
                        'terms' => array($category_id),
                    ),
                );
            }

            if ($sort === 'name') {
                $args['orderby'] = 'title';
                $args['order'] = 'ASC';
            } elseif ($sort === 'price') {
                $args['meta_key'] = '_price';
                $args['orderby'] = 'meta_value_num';
                $args['order'] = 'ASC';
            } else {
                $args['orderby'] = 'date';
                $args['order'] = 'DESC';
            }

            $query = new WP_Query($args);
            $items = array();
            foreach ($query->posts as $post) {
                $product = wc_get_product($post->ID);
                if (!$product) {
                    continue;
                }
                $items[] = $this->format_product_summary($product);
            }

            return rest_ensure_response(array(
                'success' => true,
                'items' => $items,
                'page' => $page,
                'total' => (int) $query->found_posts,
                'total_pages' => (int) $query->max_num_pages,
            ));
        }

        public function product_detail(WP_REST_Request $request) {
            $id = absint($request['id']);
            $product = wc_get_product($id);
            if (!$product) {
                return new WP_Error('ps_product_not_found', 'محصول پیدا نشد.', array('status' => 404));
            }

            $data = $this->format_product_summary($product);
            $data['categories'] = $this->get_product_categories($id);
            $data['attributes'] = $this->get_product_attributes($product);
            $data['short_description'] = wp_strip_all_tags($product->get_short_description());
            $data['description'] = wp_strip_all_tags($product->get_description());

            return rest_ensure_response($data);
        }

        public function save_specs(WP_REST_Request $request) {
            $id = absint($request['id']);
            $product = wc_get_product($id);
            if (!$product) {
                return new WP_Error('ps_product_not_found', 'محصول پیدا نشد.', array('status' => 404));
            }

            $params = $request->get_json_params();
            if (!is_array($params)) {
                return new WP_Error('ps_bad_request', 'داده ارسالی معتبر نیست.', array('status' => 400));
            }

            $mode = isset($params['mode']) ? sanitize_text_field((string) $params['mode']) : 'append';
            if (!in_array($mode, array('append', 'replace'), true)) {
                $mode = 'append';
            }

            $specs = isset($params['specs']) && is_array($params['specs']) ? $params['specs'] : array();
            $clean_specs = array();
            foreach ($specs as $row) {
                if (!is_array($row)) {
                    continue;
                }
                $name = isset($row['name']) ? sanitize_text_field((string) $row['name']) : '';
                $value = isset($row['value']) ? sanitize_text_field((string) $row['value']) : '';
                if ($name === '' || $value === '') {
                    continue;
                }
                $clean_specs[] = array('name' => $name, 'value' => $value);
            }

            if (empty($clean_specs)) {
                return new WP_Error('ps_empty_specs', 'هیچ مشخصه معتبری برای ذخیره ارسال نشده است.', array('status' => 400));
            }

            $product_content = '';
            if (isset($params['product_content'])) {
                $product_content = trim(wp_kses_post((string) $params['product_content']));
                if ($product_content !== '') {
                    $required_sentence = 'این محصول با ارسال فوری از بازار قفل سفارش بدید';
                    if (strpos(wp_strip_all_tags($product_content), $required_sentence) === false) {
                        $product_content .= ' ' . $required_sentence;
                    }
                }
            }

            $attributes = $product->get_attributes();
            $new_attributes = array();

            if ($mode === 'append') {
                foreach ($attributes as $key => $attribute) {
                    $new_attributes[$key] = $attribute;
                }
            } else {
                // در حالت جایگزینی، فقط ویژگی‌های taxonomy حفظ می‌شوند و ویژگی‌های اختصاصی قبلی جایگزین می‌شوند.
                foreach ($attributes as $key => $attribute) {
                    if (is_object($attribute) && method_exists($attribute, 'is_taxonomy') && $attribute->is_taxonomy()) {
                        $new_attributes[$key] = $attribute;
                    }
                }
            }

            $position = count($new_attributes);
            foreach ($clean_specs as $spec) {
                $key = $this->custom_attribute_key($spec['name']);
                $attr = new WC_Product_Attribute();
                $attr->set_id(0); // بسیار مهم: 0 یعنی Global Attribute نیست.
                $attr->set_name($spec['name']); // بدون pa_ و بدون taxonomy
                $attr->set_options(array($spec['value']));
                $attr->set_position($position++);
                $attr->set_visible(true);
                $attr->set_variation(false);
                $new_attributes[$key] = $attr;
            }

            $product->set_attributes($new_attributes);
            if ($product_content !== '') {
                $product->set_short_description($product_content);
            }
            $product->save();

            update_post_meta($id, '_ps_specs_updated', current_time('mysql'));
            update_post_meta($id, '_ps_specs_last_mode', $mode);
            if (isset($params['raw_text'])) {
                update_post_meta($id, '_ps_specs_last_raw_text', sanitize_textarea_field((string) $params['raw_text']));
            }
            if (isset($params['ai_provider'])) {
                update_post_meta($id, '_ps_specs_last_ai_provider', sanitize_text_field((string) $params['ai_provider']));
            }
            if ($product_content !== '') {
                update_post_meta($id, '_ps_specs_last_product_content', wp_strip_all_tags($product_content));
            }

            wc_delete_product_transients($id);
            clean_post_cache($id);

            return rest_ensure_response(array(
                'success' => true,
                'message' => 'مشخصات با موفقیت روی محصول ذخیره شد.',
                'mode' => $mode,
                'saved_count' => count($clean_specs),
                'content_saved' => $product_content !== '',
                'attributes' => $this->get_product_attributes(wc_get_product($id)),
            ));
        }

        private function format_product_summary($product) {
            $image_id = $product->get_image_id();
            $image = $image_id ? wp_get_attachment_image_url($image_id, 'medium') : '';
            $attrs = $product->get_attributes();
            return array(
                'id' => (int) $product->get_id(),
                'name' => $product->get_name(),
                'sku' => $product->get_sku(),
                'price' => wc_format_localized_price($product->get_price()),
                'raw_price' => $product->get_price(),
                'image' => $image ? $image : '',
                'link' => get_permalink($product->get_id()),
                'has_specs' => !empty($attrs),
                'updated_by_app' => (bool) get_post_meta($product->get_id(), '_ps_specs_updated', true),
            );
        }

        private function get_product_categories($product_id) {
            $terms = get_the_terms($product_id, 'product_cat');
            if (!$terms || is_wp_error($terms)) {
                return array();
            }
            $out = array();
            foreach ($terms as $term) {
                $out[] = array('id' => (int) $term->term_id, 'name' => $term->name);
            }
            return $out;
        }

        private function get_product_attributes($product) {
            $out = array();
            if (!$product) {
                return $out;
            }

            foreach ($product->get_attributes() as $attribute) {
                if (!is_object($attribute)) {
                    continue;
                }

                if ($attribute->is_taxonomy()) {
                    $taxonomy = $attribute->get_name();
                    $label = wc_attribute_label($taxonomy);
                    $terms = wc_get_product_terms($product->get_id(), $taxonomy, array('fields' => 'names'));
                    $value = is_array($terms) ? implode('، ', $terms) : '';
                    $out[] = array(
                        'name' => $label,
                        'value' => $value,
                        'is_taxonomy' => true,
                        'is_visible' => (bool) $attribute->get_visible(),
                        'is_variation' => (bool) $attribute->get_variation(),
                    );
                } else {
                    $options = $attribute->get_options();
                    $value = is_array($options) ? implode('، ', array_map('wc_clean', $options)) : '';
                    $out[] = array(
                        'name' => $attribute->get_name(),
                        'value' => $value,
                        'is_taxonomy' => false,
                        'is_visible' => (bool) $attribute->get_visible(),
                        'is_variation' => (bool) $attribute->get_variation(),
                    );
                }
            }
            return $out;
        }

        private function custom_attribute_key($name) {
            $base = sanitize_title($name);
            if ($base === '') {
                $base = 'ps_' . substr(md5($name), 0, 10);
            }
            // عمداً pa_ اضافه نمی‌شود تا ویژگی عمومی ووکامرس ساخته نشود.
            if (strpos($base, 'pa_') === 0) {
                $base = 'custom_' . substr($base, 3);
            }
            return $base;
        }
    }
}

register_activation_hook(__FILE__, array('PS_Product_Specs_API', 'activate'));
new PS_Product_Specs_API();
