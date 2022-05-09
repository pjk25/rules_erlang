load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

OTP_BUILD_FILE_CONTENT = """load(
    "@rules_erlang//tools:erlang.bzl",
    "standard_erlang_tools",
)
load(
    "@rules_erlang//tools/app_file_tool:app_file_tool.bzl",
    "app_file_tool",
)
load(
    "@rules_erlang//tools/compile_first:compile_first.bzl",
    "compile_first",
)
load(
    "@rules_erlang//tools/shard_suite:shard_suite.bzl",
    "shard_suite",
)

standard_erlang_tools()
app_file_tool()
compile_first()
shard_suite()
"""

def _merge(an_archive, archives):
    for archive in archives:
        if archive["url"] == an_archive["url"]:
            if archive == an_archive:
                return archives
            else:
                fail("Conflicting definitions for otp src: {}, {}".format(an_archive, archive))
    archives.append(an_archive)
    return archives

def _erlang_src(ctx):
    archives = []
    for mod in ctx.modules:
        for archive in mod.tags.http_archive:
            props = {
                "name": archive.name,
                "url": archive.url,
                "strip_prefix": archive.strip_prefix,
                "sha256": archive.sha256,
            }
            archives = _merge(props, archives)
        for release in mod.tags.github_otp_erlang_release:
            url = "https://github.com/erlang/otp/releases/download/OTP-{v}/otp_src_{v}.tar.gz".format(v = release.version)
            props = {
                "name": "otp_{}".format(release.version),
                "url": url,
                "strip_prefix": "otp_src_{}".format(release.version),
                "sha256": release.sha256,
            }
            archives = _merge(props, archives)

    for props in archives:
        http_archive(
            build_file_content = OTP_BUILD_FILE_CONTENT,
            **props
        )

http_archive_tag = tag_class(attrs = {
    "name": attr.string(),
    "url": attr.string(),
    "strip_prefix": attr.string(),
    "sha256": attr.string(),
})

github_otp_erlang_release = tag_class(attrs = {
    "version": attr.string(),
    "sha256": attr.string(),
})

erlang_src = module_extension(
    implementation = _erlang_src,
    tag_classes = {
        "http_archive": http_archive_tag,
        "github_otp_erlang_release": github_otp_erlang_release,
    },
)
