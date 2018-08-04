const TCL_OK       = convert(Int32, 0)
const TCL_ERROR    = convert(Int32, 1)
const TCL_RETURN   = convert(Int32, 2)
const TCL_BREAK    = convert(Int32, 3)
const TCL_CONTINUE = convert(Int32, 4)

const TCL_VOLATILE = convert(Ptr{Void}, 1)
const TCL_STATIC   = convert(Ptr{Void}, 0)
const TCL_DYNAMIC  = convert(Ptr{Void}, 3)

tcl_doevent() = tcl_doevent(nothing,0)
function tcl_doevent(timer,status=0)
    # https://www.tcl.tk/man/tcl8.6/TclLib/DoOneEvent.htm
    # DONT_WAIT* = 1 shl 1
    # WINDOW_EVENTS* = 1 shl 2
    # FILE_EVENTS* = 1 shl 3
    # TIMER_EVENTS* = 1 shl 4
    # IDLE_EVENTS* = 1 shl 5
    # ALL_EVENTS* = not DONT_WAIT
    while (ccall((:Tcl_DoOneEvent,libtcl), Int32, (Int32,), (1<<1))!=0)
    end
end

global timeout = nothing

# fetch first word from struct
tk_display(w) = pointer_to_array(convert(Ptr{Ptr{Void}},w), (1,), false)[1]

function init()
    @static if is_apple() ccall(:CFBundleCreate, Ptr{Void}, (Ptr{Void}, Ptr{Void}), C_NULL,
        ccall(:CFURLCreateWithFileSystemPath, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Cint, Cint), C_NULL,
            ccall(:CFStringCreateWithFileSystemRepresentation, Ptr{Void}, (Ptr{Void}, Ptr{UInt8}), C_NULL, "/System/Library/Frameworks/Tk.framework"),
            0, 1))
    end
    ccall((:Tcl_FindExecutable,libtcl), Void, (Ptr{UInt8},),
          joinpath(JULIA_HOME, "julia"))
    ccall((:g_type_init,Cairo._jl_libgobject),Void,())
    tclinterp = ccall((:Tcl_CreateInterp,libtcl), Ptr{Void}, ())
    @static if is_windows()
        htcl = ccall((:GetModuleHandleA,:kernel32),stdcall,Csize_t,
            (Ptr{UInt8},),libtcl)
        tclfile = Vector{UInt8}(260)
        len = ccall((:GetModuleFileNameA,:kernel32),stdcall,Cint,
            (Csize_t,Ptr{UInt8},Cint),htcl,tclfile,length(tclfile))
        if len > 0
            tcldir = dirname(String(tclfile[1:len]))
            libpath = IOBuffer()
            print(libpath,"set env(TCL_LIBRARY) [subst -nocommands -novariables {")
            escape_string(libpath,abspath(tcldir,"..","share","tcl"),"{}")
            print(libpath,"}]")
            tcl_eval(String(take!(libpath)),tclinterp)
            print(libpath,"set env(TK_LIBRARY) [subst -nocommands -novariables {")
            escape_string(libpath,abspath(tcldir,"..","share","tk"),"{}")
            print(libpath,"}]")
            tcl_eval(String(take!(libpath)),tclinterp)
        end
    end
    if ccall((:Tcl_Init,libtcl), Int32, (Ptr{Void},), tclinterp) == TCL_ERROR
        throw(TclError(string("error initializing Tcl: ", tcl_result(tclinterp))))
    end
    if ccall((:Tk_Init,libtk), Int32, (Ptr{Void},), tclinterp) == TCL_ERROR
        throw(TclError(string("error initializing Tk: ", tcl_result(tclinterp))))
    end
    global timeout
    timeout = Timer(tcl_doevent,0.1,0.01)
    tclinterp
end

mainwindow(interp) =
    ccall((:Tk_MainWindow,libtk), Ptr{Void}, (Ptr{Void},), interp)
mainwindow() = mainwindow(tcl_interp)

type TclError <: Exception
    msg::AbstractString
end

tcl_result() = tcl_result(tcl_interp)
function tcl_result(tcl_interp)
    unsafe_string(ccall((:Tcl_GetStringResult,libtcl),
                        Ptr{UInt8}, (Ptr{Void},), tcl_interp))
end

function tcl_evalfile(name)
    if ccall((:Tcl_EvalFile,libtcl), Int32, (Ptr{Void}, Ptr{UInt8}),
             tcl_interp, name) != 0
        throw(TclError(tcl_result()))
    end
    nothing
end

tcl_eval(cmd) = tcl_eval(cmd,tcl_interp)
function tcl_eval(cmd,tclinterp)
    code = ccall((:Tcl_Eval,libtcl), Int32, (Ptr{Void}, Ptr{UInt8}),
                 tclinterp, cmd)
    result = tcl_result(tclinterp)
    if code != 0
        throw(TclError(result))
    else
        result
    end
end

type TkWidget
    path::String
    kind::String
    parent::Union{TkWidget,Void}

    let ID::Int = 0
    function TkWidget(parent::TkWidget, kind)
        underscoredKind = replace(kind, "::", "_")
        path = "$(parent.path).jl_$(underscoredKind)$(ID)"; ID += 1
        new(path, kind, parent)
    end
    global Window
    function Window(title, w, h, visible = true)
        wpath = ".jl_win$ID"; ID += 1
        tcl_eval("toplevel $wpath -width $w -height $h -background \"\"")
        if !visible
            tcl_eval("wm withdraw $wpath")
        end
        tcl_eval("wm title $wpath \"$title\"")
        tcl_doevent()
        new(wpath, "toplevel", nothing)
    end
    end
end

Window(title) = Window(title, 200, 200)

place(widget::TkWidget, x::Int, y::Int) = tcl_eval("place $(widget.path) -x $x -y $y")

function nametowindow(name)
    ccall((:Tk_NameToWindow,libtk), Ptr{Void},
          (Ptr{Void}, Ptr{UInt8}, Ptr{Void}),
          tcl_interp, name, mainwindow(tcl_interp))
end

const _callbacks = ObjectIdDict()

const empty_str = ""

function jl_tcl_callback(fptr, interp, argc::Int32, argv::Ptr{Ptr{UInt8}})
    f = unsafe_pointer_to_objref(fptr)
    args = [unsafe_string(unsafe_load(argv,i)) for i=1:argc]
    local result
    try
        result = f(args...)
    catch e
        println("error during Tk callback: ")
        Base.display_error(e,catch_backtrace())
        return TCL_ERROR
    end
    if isa(result,String)
        ccall((:Tcl_SetResult,libtcl), Void, (Ptr{Void}, Ptr{UInt8}, Int32),
              interp, result, TCL_VOLATILE)
    else
        ccall((:Tcl_SetResult,libtcl), Void, (Ptr{Void}, Ptr{UInt8}, Int32),
              interp, empty_str, TCL_STATIC)
    end
    return TCL_OK
end

jl_tcl_callback_ptr = cfunction(jl_tcl_callback,
                                Int32, (Ptr{Void}, Ptr{Void}, Int32, Ptr{Ptr{UInt8}}))

function tcl_callback(f)
    cname = string("jl_cb", repr(object_id(f)))
    # TODO: use Tcl_CreateObjCommand instead
    ccall((:Tcl_CreateCommand,libtcl), Ptr{Void},
          (Ptr{Void}, Ptr{UInt8}, Ptr{Void}, Ptr{Void}, Ptr{Void}),
          tcl_interp, cname, jl_tcl_callback_ptr, pointer_from_objref(f), C_NULL)
    # TODO: use a delete proc (last arg) to remove this
    _callbacks[f] = true
    cname
end

width(w::TkWidget) = parse(Int, tcl_eval("winfo width $(w.path)"))
height(w::TkWidget) = parse(Int, tcl_eval("winfo height $(w.path)"))

const default_mouse_cb = (w, x, y)->nothing

type MouseHandler
    button1press
    button1release
    button2press
    button2release
    button3press
    button3release
    motion
    button1motion

    MouseHandler() = new(default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb)
end

# TkCanvas is the plain Tk canvas widget. This one is double-buffered
# and built on Cairo.
type Canvas
    c::TkWidget
    back::CairoSurface   # backing store
    backcc::CairoContext
    mouse::MouseHandler
    draw
    resize
    initialized::Bool

    Canvas(parent) = Canvas(parent, -1, -1)
    function Canvas(parent, w, h)
        c = TkWidget(parent, "ttk::frame")
        # frame supports empty background, allowing us to control drawing
        if w < 0
            w = width(parent)
        end
        if h < 0
            h = height(parent)
        end
        this = new(c)
        tcl_eval("frame $(c.path) -width $w -height $h -background \"\"")
        this.draw = x->nothing
        this.resize = x->nothing
        this.mouse = MouseHandler()
        this.initialized = false
        add_canvas_callbacks(this)
        this
    end
end

width(c::Canvas) = width(c.c)
height(c::Canvas) = height(c.c)

function configure(c::Canvas)
    # this is called e.g. on window resize
    if isdefined(c,:back)
        Cairo.destroy(c.backcc)
        Cairo.destroy(c.back)
    end
    render_to_cairo(c.c, false) do surf
        w = width(c.c)
        h = height(c.c)
        c.back = surface_create_similar(surf, w, h)
    end
    c.backcc = CairoContext(c.back)
    # Check c.initialized to prevent infinite recursion if initialized from
    # c.resize. This also avoids a double-redraw on the first call.
    if c.initialized
        c.resize(c)
        draw(c)
    end
end

function draw(c::Canvas)
    c.draw(c)
    reveal(c)
end

function reveal(c::Canvas)
    render_to_cairo(c.c) do front
        frontcc = CairoContext(front)
        back = cairo_surface(c)
        set_source_surface(frontcc, back, 0, 0)
        paint(frontcc)
        destroy(frontcc)
    end
    tcl_doevent()
end

@static if is_apple()
    if Sys.WORD_SIZE == 32
        const CGFloat = Float32
    else
        const CGFloat = Float64
    end
    function objc_msgSend{T}(id, uid, ::Type{T}=Ptr{Void})
        convert(T, ccall(:objc_msgSend, Ptr{Void}, (Ptr{Void}, Ptr{Void}),
                         id, ccall(:sel_getUid, Ptr{Void}, (Ptr{UInt8},), uid)))
    end
end

# NOTE: This has to be ported to each window environment.
# But, this should be the only such function needed.
function render_to_cairo(f::Function, w::TkWidget, clipped::Bool=true)
    win = nametowindow(w.path)
    win == C_NULL && error("invalid window")
    @static if is_linux()
        disp = jl_tkwin_display(win)
        d = jl_tkwin_id(win)
        vis = jl_tkwin_visual(win)
        if disp==C_NULL || d==0 || vis==C_NULL
            error("invalid window")
        end
        surf = CairoXlibSurface(disp, d, vis, width(w), height(w))
        f(surf)
        destroy(surf)
        return
    end
    @static if is_apple()
        ## TkMacOSXSetupDrawingContext()
        drawable = jl_tkwin_id(win)
        view = ccall((:TkMacOSXGetRootControl,libtk), Ptr{Void}, (Int,), drawable) # NSView*
        if view == C_NULL
            error("Invalid OS X window at getView")
        end
        focusView = objc_msgSend(ccall(:objc_getClass, Ptr{Void}, (Ptr{UInt8},), "NSView"), "focusView");
        focusLocked = false
        if view != focusView
            focusLocked = objc_msgSend(view, "lockFocusIfCanDraw", Int32) != 0
            dontDraw = !focusLocked
        else
            dontDraw = 0 == objc_msgSend(view, "canDraw", Int32)
        end
        if dontDraw
            error("Cannot draw to OS X Window")
        end
        window = objc_msgSend(view, "window")
        objc_msgSend(window, "disableFlushWindow")
        context = objc_msgSend(objc_msgSend(window, "graphicsContext"), "graphicsPort")
        if !focusLocked
            ccall(:CGContextSaveGState, Void, (Ptr{Void},), context)
        end
        try
            ## TkMacOSXGetClipRgn
            wi, hi = width(w), height(w)
            if clipped
                macDraw = unsafe_load(convert(Ptr{TkWindowPrivate}, drawable))
                if macDraw.winPtr != C_NULL
                    TK_CLIP_INVALID = 0x02 # 8.4, 8.5, 8.6
                    if macDraw.flags & TK_CLIP_INVALID != 0
                        ccall((:TkMacOSXUpdateClipRgn,libtk), Void, (Ptr{Void},), macDraw.winPtr)
                        macDraw = unsafe_load(convert(Ptr{TkWindowPrivate}, drawable))
                    end
                    clipRgn = if macDraw.drawRgn != C_NULL
                        macDraw.drawRgn
                    elseif macDraw.visRgn != C_NULL
                        macDraw.visRgn
                    else
                        C_NULL
                    end
                end
                ##
                ccall(:CGContextTranslateCTM, Void, (Ptr{Void}, CGFloat, CGFloat), context, 0, height(toplevel(w)))
                ccall(:CGContextScaleCTM, Void, (Ptr{Void}, CGFloat, CGFloat), context, 1, -1)
                if clipRgn != C_NULL
                    if ccall(:HIShapeIsEmpty, UInt8, (Ptr{Void},), clipRgn) != 0
                        return
                    end
                    @assert 0 == ccall(:HIShapeReplacePathInCGContext, Cint, (Ptr{Void}, Ptr{Void}), clipRgn, context)
                    ccall(:CGContextEOClip, Void, (Ptr{Void},), context)
                end
                ccall(:CGContextTranslateCTM, Void, (Ptr{Void}, CGFloat, CGFloat), context, macDraw.xOff, macDraw.yOff)
                ##
            end
            surf = CairoQuartzSurface(context, wi, hi)
            try
                f(surf)
            finally
                destroy(surf)
            end
        finally
            ## TkMacOSXRestoreDrawingContext
            ccall(:CGContextSynchronize, Void, (Ptr{Void},), context)
            objc_msgSend(window, "enableFlushWindow")
            if focusLocked
                objc_msgSend(view, "unlockFocus")
            else
                ccall(:CGContextRestoreGState, Void, (Ptr{Void},), context)
            end
        end
        ##
        return
    end
    @static if is_windows()
        state = Vector{UInt8}(sizeof(Int)*2) # 8.4, 8.5, 8.6
        drawable = jl_tkwin_id(win)
        hdc = ccall((:TkWinGetDrawableDC,libtk), Ptr{Void}, (Ptr{Void}, Int, Ptr{UInt8}),
            jl_tkwin_display(win), drawable, state)
        surf = CairoWin32Surface(hdc, width(w), height(w))
        f(surf)
        destroy(surf)
        ccall((:TkWinReleaseDrawableDC,libtk), Void, (Int, Int, Ptr{UInt8}),
            drawable, hdc, state)
        return
    end
    error("Unsupported Operating System")
end

function add_canvas_callbacks(c::Canvas)
    # See Table 15-3 of http://oreilly.com/catalog/mastperltk/chapter/ch15.html
    # A widget has been mapped onto the display and is visible
    bind(c, "<Map>", path -> init_canvas(c))
    # All or part of a widget has been uncovered and may need to be redrawn
    bind(c, "<Expose>", path -> reveal(c))
    # A widget has changed size or position and may need to adjust its layout
    bind(c, "<Configure>", path -> configure(c))
    # A mouse button was pressed
    bind(c, "<ButtonPress-1>", (path,x,y)->(c.mouse.button1press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-1>", (path,x,y)->(c.mouse.button1release(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonPress-2>",   (path,x,y)->(c.mouse.button2press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-2>", (path,x,y)->(c.mouse.button2release(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonPress-3>",   (path,x,y)->(c.mouse.button3press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-3>", (path,x,y)->(c.mouse.button3release(c, parse(Int, x), parse(Int, y))))
    # The cursor is in motion over a widget
    bind(c, "<Motion>",          (path,x,y)->(c.mouse.motion(c, parse(Int, x), parse(Int, y))))
    bind(c, "<Button1-Motion>",  (path,x,y)->(c.mouse.button1motion(c, parse(Int, x), parse(Int, y))))
end

# some canvas init steps require the widget to fully exist
# this is called once per Canvas, before doing anything else with it
function init_canvas(c::Canvas)
    c.initialized = true
    configure(c)
    c
end

get_visible(c::Canvas) = get_visible(c.c.parent)

initialized(c::Canvas) = c.initialized

function pack(c::Canvas, args...)
    pack(c.c, args...)
end

function grid(c::Canvas, args...)
    grid(c.c, args...)
end

function place(c::Canvas, x::Int, y::Int)
    place(c.c, x, y)
end


function update()
    tcl_eval("update")
end

function wait_initialized(c::Canvas)
    n = 0
    while !initialized(c)
        tcl_doevent()
        n += 1
        if n > 10000
            error("getgc: Canvas is not drawable")
        end
    end
end

function getgc(c::Canvas)
    wait_initialized(c)
    c.backcc
end

function cairo_surface(c::Canvas)
    wait_initialized(c)
    c.back
end

const tcl_interp = init()
const tk_version = convert(VersionNumber,tcl_eval("return \$tk_version"))
tcl_eval("wm withdraw .")

if tk_version >= v"8.4-" && tk_version < v"8.7-"
jl_tkwin_display(tkwin::Ptr{Void}) = unsafe_load(convert(Ptr{Ptr{Void}},tkwin), 1) # 8.4, 8.5, 8.6
jl_tkwin_visual(tkwin::Ptr{Void}) = unsafe_load(convert(Ptr{Ptr{Void}},tkwin), 4) # 8.4, 8.5, 8.6
jl_tkwin_id(tkwin::Ptr{Void}) = unsafe_load(convert(Ptr{Int},tkwin), 6) # 8.4, 8.5, 8.6
if is_apple()
if tk_version >= v"8.5-"
    immutable TkWindowPrivate
        winPtr::Ptr{Void}
        view::Ptr{Void}
        context::Ptr{Void}
        xOff::Cint
        yOff::Cint
        sizeX::CGFloat;
        sizeY::CGFloat;
        visRgn::Ptr{Void}
        aboveVisRgn::Ptr{Void}
        drawRgn::Ptr{Void}
        referenceCount::Ptr{Void}
        toplevel::Ptr{Void}
        flags::Cint
    end
    else
    immutable TkWindowPrivate
        winPtr::Ptr{Void}
        grafPtr::Ptr{Void}
        view::Ptr{Void}
        context::Ptr{Void}
        xOff::Cint
        yOff::Cint
        sizeX::CGFloat;
        sizeY::CGFloat;
        visRgn::Ptr{Void}
        aboveVisRgn::Ptr{Void}
        drawRgn::Ptr{Void}
        referenceCount::Ptr{Void}
        toplevel::Ptr{Void}
        flags::Cint
    end
    end
end
else
error("Tk.jl needs to be updated for tk version $tk_version")
end
