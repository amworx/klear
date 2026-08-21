// ============================================================
// Klear — Admin Create User Edge Function
// Called by the admin dashboard ("Klear Control Center") when an
// admin adds a new client (customer) or supplier (provider).
//
// The web app only has the publishable anon key; creating a
// profile requires an auth.users row (profiles.id references
// auth.users.id), so user creation must run server-side with the
// service role. This function:
//   1. Verifies the caller is an authenticated admin.
//   2. Creates the auth user (email confirmed, so they can log in
//      via email OTP immediately).
//   3. Creates the matching profile row with the given role.
// ============================================================

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'apikey, content-type, authorization, x-client-info, x-supabase-api-version',
  'Access-Control-Max-Age': '86400',
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }

  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    const { email, full_name, phone, role } = await req.json()

    if (!email || typeof email !== 'string' || !email.trim()) {
      return jsonResponse({ error: 'email is required' }, 400)
    }
    if (role !== 'customer' && role !== 'provider') {
      return jsonResponse({ error: "role must be 'customer' or 'provider'" }, 400)
    }

    // ----------------------------------------------------------
    // 1) Verify the caller is an authenticated admin.
    //    The dashboard sends the anon key + the signed-in user's
    //    JWT in the Authorization header.
    // ----------------------------------------------------------
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

    const authHeader = req.headers.get('Authorization') || ''
    const jwt = authHeader.replace(/^Bearer\s+/i, '')

    if (!jwt) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    // Resolve the caller's identity from their JWT (works with anon key).
    const anonClient = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_ANON_KEY') || '',
      { global: { headers: { Authorization: `Bearer ${jwt}` } } }
    )
    const { data: { user: caller }, error: callerError } = await anonClient.auth.getUser(jwt)
    if (callerError || !caller) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const { data: callerProfile } = await anonClient
      .from('profiles')
      .select('role')
      .eq('id', caller.id)
      .single()

    if (!callerProfile || callerProfile.role !== 'admin') {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    // ----------------------------------------------------------
    // 2) Create the auth user + profile with the service role.
    // ----------------------------------------------------------
    const admin = createClient(supabaseUrl, serviceKey)

    const normalizedEmail = email.trim().toLowerCase()

    const { data: authUser, error: createError } = await admin.auth.admin.createUser({
      email: normalizedEmail,
      email_confirm: true,
      user_metadata: {
        full_name: full_name?.trim() || null,
        phone: phone?.trim() || null,
      },
    })

    if (createError) {
      // Surface duplicate-email / validation errors cleanly.
      const duplicate = /already been registered/i.test(createError.message)
      return jsonResponse(
        { error: duplicate ? 'A user with this email already exists' : createError.message },
        duplicate ? 409 : 400
      )
    }

    if (!authUser?.user?.id) {
      return jsonResponse({ error: 'Failed to create user' }, 500)
    }

    const { error: profileError } = await admin.from('profiles').insert({
      id: authUser.user.id,
      full_name: full_name?.trim() || null,
      phone: phone?.trim() || null,
      role,
      is_active: true,
    })

    if (profileError) {
      // Best effort: if the profile insert fails, clean up the auth
      // user so we don't leave a half-created account behind.
      await admin.auth.admin.deleteUser(authUser.user.id).catch(() => {})
      return jsonResponse({ error: `Failed to create profile: ${profileError.message}` }, 500)
    }

    console.log(`Admin created ${role} ${normalizedEmail}`)

    return jsonResponse({
      success: true,
      profile: {
        id: authUser.user.id,
        email: normalizedEmail,
        full_name: full_name?.trim() || null,
        phone: phone?.trim() || null,
        role,
        is_active: true,
      },
    }, 200)
  } catch (error) {
    console.error('Error in admin-create-user:', error)
    return jsonResponse({ error: error.message || 'Internal error' }, 500)
  }
})