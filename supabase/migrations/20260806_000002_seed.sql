-- Klear: seed catalog (run after the base migration).
insert into public.services (name_ar, name_en, desc_ar, desc_en, base_price, currency, is_active, sort)
values
  ('تنظيف داخلي', 'Interior Cleaning', 'تنظيف بالمكنسة ومسح كامل للمقصورة', 'Deep interior vacuum and full wipe', 15000, 'SYP', true, 1),
  ('غسيل خارجي', 'Exterior Wash', 'غسيل وشطف خارجي بمستوى احترافي', 'Premium exterior wash and rinse', 20000, 'SYP', true, 2),
  ('باقة العناية الكاملة', 'Full Care Package', 'تنظيف شامل من الداخل والخارج', 'Comprehensive inside-and-out cleaning', 30000, 'SYP', true, 3)
on conflict (id) do nothing;