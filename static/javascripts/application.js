var Stats = Backbone.Model.extend({
    url: "/stats",
    defaults: {
        "Status": "initializing",
        "StartedAt": null,
        "FinishedAt": null,
        "Progress": 0,
        "Targets": 0,
        "Repositories": 0,
        "Commits": 0,
        "Files": 0,
        "Findings": 0,
    },
    isFinished: function () {
        return this.get("Status") === "finished";
    },
    duration: function () {
        if (this.get("StartedAt") === null) {
            return "00:00:00";
        }
        var end;
        var start = Date.parse(this.get("StartedAt"));
        if (this.isFinished()) {
            end = Date.parse(this.get("FinishedAt"));
        } else {
            end = Date.now();
        }
        var millis = end - start;
        var seconds = Math.floor(millis / 1000);
        var nullDate = new Date(null);
        nullDate.setSeconds(seconds);
        return nullDate.toISOString().substr(11, 8);
    },
});
window.stats = new Stats;

var Finding = Backbone.Model.extend({
    idAttribute: "Id",
    testFileIndicators: ["test", "_spec", "fixture", "mock", "stub", "fake", "demo", "sample"],
    shortCommitHash: function () {
        return this.get("CommitHash").substr(0, 7);
    },
    trimmedCommitMessage: function () {
        var message = this.get("CommitMessage").split("-----END PGP SIGNATURE-----", 2).pop();
        return message.replace(/^\s\s*/, "").replace(/\s\s*$/, "")
    },
    isTestRelated: function () {
        var path = this.get("FilePath").toLowerCase();
        for (var i = 0; i < this.testFileIndicators.length; i++) {
            if (path.indexOf(this.testFileIndicators[i]) > -1) {
                return true;
            }
        }
        return false;
    },
    fileContentsUrl: function () {
        return ["/files", this.get("RepositoryOwner"), this.get("RepositoryName"), this.get("CommitHash"), this.get("FilePath")].join("/");
    },
    fileContents: function (callback, error) {
        $.ajax({
            url: this.fileContentsUrl(),
            success: callback,
            error: error
        });
    },
});

var Findings = Backbone.Collection.extend({
    url: "/findings",
    model: Finding,
});

window.findings = new Findings();

var StatsView = Backbone.View.extend({
    id: "stats_container",
    model: stats,
    pollingTicker: null,
    durationTicker: null,
    pollingInterval: 500,
    initialize: function () {
        this.listenTo(this.model, "change", this.render);
        this.startDurationTicker();
        this.startPolling();
    },
    render: function () {
        if (this.model.isFinished()) {
            this.stopPolling();
            this.stopDurationTicker();
        }
        if (this.model.hasChanged("Progress")) {
            this.updateProgress();
        }
        if (this.model.hasChanged("Findings")) {
            this.updateFindings();
        }
        if (this.model.hasChanged("Files")) {
            this.updateFiles();
        }
        if (this.model.hasChanged("Commits")) {
            this.updateCommits();
        }
        if (this.model.hasChanged("Repositories")) {
            this.updateRepositories();
        }
        if (this.model.hasChanged("Targets")) {
            this.updateTargets();
        }
    },
    startPolling: function () {
        this.pollingTicker = setInterval(function () {
            statsView.model.fetch();
        }, this.pollingInterval);
    },
    stopPolling: function () {
        if (this.pollingTicker !== null) {
            clearInterval(this.pollingTicker);
        }
    },
    startDurationTicker: function () {
        this.DurationTicker = setInterval(function () {
            statsView.updateDuration()
        }, 1000);
    },
    stopDurationTicker: function () {
        this.updateDuration();
        if (this.durationTicker !== null) {
            clearInterval(this.durationTicker);
        }
    },
    updateDuration: function () {
        $("#card_duration_value").text(this.model.duration());
    },
    updateProgress: function () {
        var status = this.statusToHuman();
        $("title").text("Gitrob: " + status);
        $("#progress_bar").text(status).css("width", this.model.get("Progress") + "%");
        if (this.model.isFinished()) {
            $("#progress_bar").removeClass("progress-bar-animated progress-bar-striped").css("width", "100%");
        }
    },
    updateFindings: function () {
        $("#card_findings_value").hide().text(this.model.get("Findings").toLocaleString()).fadeIn("fast");
    },
    updateFiles: function () {
        $("#card_files_value").hide().text(this.model.get("Files").toLocaleString()).fadeIn("fast");
    },
    updateCommits: function () {
        $("#card_commits_value").hide().text(this.model.get("Commits").toLocaleString()).fadeIn("fast");
    },
    updateRepositories: function () {
        $("#card_repositories_value").hide().text(this.model.get("Repositories").toLocaleString()).fadeIn("fast");
    },
    updateTargets: function () {
        $("#card_targets_value").hide().text(this.model.get("Targets").toLocaleString()).fadeIn("fast");
    },
    statusToHuman: function () {
        var status;
        switch (this.model.get("Status")) {
            case "initializing":
                status = "Initializing";
                break;
            case "gathering":
                status = "Gathering repositories";
                break;
            case "analyzing":
                status = "Analyzing repositories";
                break;
            case "finished":
                status = "Finished";
                break;
            default:
                status = "Unknown";
                break;
        }
        return status + " (" + parseInt(this.model.get("Progress")) + "%)";
    }
});
window.statsView = new StatsView({el: $("#stats_container")});

var FindingView = Backbone.View.extend({
    tagName: "tr",
    events: {
        "click td.col-path a": "showFinding",
    },
    template: _.template($("#template_finding").html()),
    render: function () {
        this.$el.html(this.template(this.model.attributes)).data("finding", this.model);
        if (this.model.isTestRelated()) {
            this.$el.addClass("test-related");
        }
        return this;
    },
    formattedFilePath: function () {
        var splits = this.model.get("FilePath").split("/");
        var filename = splits.pop();
        var directory = this.ellipsisize(splits.join("/"), 60, 25);
        if (directory === "") {
            return "<strong>" + _.escape(filename) + "</strong>";
        }
        return _.escape(directory) + "/" + "<strong>" + _.escape(filename) + "</strong>";
    },
    ellipsisize: function (str, minLength, edgeLength) {
        str = String(str);
        if (str.length < minLength || str.length <= (edgeLength * 2)) {
            return str;
        }
        var edge = Array(edgeLength + 1).join(".");
        var midLength = str.length - edgeLength * 2;
        var pattern = "(" + edge + ").{" + midLength + "}(" + edge + ")";
        return str.replace(new RegExp(pattern), "$1…$2");
    },
    showFinding: function (e) {
        e.preventDefault();
        this.markAsSelected();
        var modalView = new FindingModal({
            model: this.model,
            el: "#finding_modal .modal-content"
        });
        modalView.render();
        $("#finding_modal").modal();
        modalView.fetchFileContents();
    },
    markAsSelected: function () {
        this.$el.closest("tbody").find("tr.table-selected").removeClass("table-selected");
        this.$el.addClass("table-selected");
    },
});

var FindingsView = Backbone.View.extend({
    collection: findings,
    initialize: function () {
        this.listenTo(this.collection, "add", this.renderFinding);
        this.listenTo(stats, "change:Findings", _.debounce(this.update, 500));
        $("#findings_search").on("keyup", _.debounce(this.searchFindings, 200));
        $("#finding_modal").on("show.bs.modal", function (event) {
            $(document).on("keydown", function (e) {
                switch (e.keyCode) {
                    case 37:
                        var finding = findingsView.previousFinding();
                        break;
                    case 39:
                        var finding = findingsView.nextFinding();
                        break;
                    default:
                        return;
                }
                if (finding.length === 0) {
                    return;
                }
                findingsView.activeFinding().removeClass("table-selected");
                finding.addClass("table-selected");
                var modalView = new FindingModal({
                    model: finding.data("finding"),
                    el: "#finding_modal .modal-content"
                });
                modalView.render();
                $("#finding_modal").modal();
                modalView.fetchFileContents();
            });
        })
            .on("hidden.bs.modal", function (event) {
                $(document).unbind("keydown");
            });
    },
    update: function () {
        this.collection.fetch();
    },
    renderFinding: function (finding) {
        var findingEl = new FindingView({model: finding}).render().el;
        $(findingEl).appendTo(this.$el);
    },
    activeFinding: function () {
        return this.$el.find("tr.table-selected");
    },
    nextFinding: function () {
        return this.activeFinding().nextAll("tr").not(".d-none").first();
    },
    previousFinding: function () {
        return this.activeFinding().prevAll("tr").not(".d-none").first();
    },
    searchFindings: function () {
        var needle = $.trim($("#findings_search").val()).toLowerCase();
        if (needle == "") {
            $("#table_findings tbody tr").removeClass("d-none");
            return;
        }
        $("#table_findings tbody tr").each(function () {
            var path = $(this).find("td.col-path").text().toLowerCase();
            var commit = $(this).find("td.col-commit").text().toLowerCase();
            var repository = $(this).find("td.col-repository").text().toLowerCase();
            if (path.indexOf(needle) > -1 || commit.indexOf(needle) > -1 || repository.indexOf(needle) > -1) {
                $(this).removeClass("d-none");
            } else {
                $(this).addClass("d-none");
            }
        });
    }
});
window.findingsView = new FindingsView({el: "#table_findings tbody"});

var FindingModal = Backbone.View.extend({
    template: _.template($("#template_finding_modal").html()),
    interestingStringPatterns: [
        /((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))/gmi,
        /([a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)/gmi,
        /((\w*:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6}))/gmi,
        /([a-f0-9\-\$\/]{20,})/gmi,
        /(username)/gmi,
        /(secret)/gmi,
        /(passw(or)?d)/gmi,
        /(cred(s|ential))/gmi,
        /(access(_|-|.)?token)/gmi,
    ],
    events: {
        "click #finding_view_raw": "showRawContents",
        "click #finding_view_hexdump": "showHexDumpContents",
    },
    render: function () {
        this.$el.html(this.template(this.model.attributes));
        new ClipboardJS('.btn', {
            container: document.getElementById('finding_modal')
        });
        return this;
    },
    showRawContents: function () {
        $("#finding_view_raw").addClass("active");
        $("#finding_view_hexdump").removeClass("active");
        $("#modal_file_hexdump").hide();
        $("#modal_file_contents").show();
    },
    showHexDumpContents: function () {
        $("#finding_view_raw").removeClass("active");
        $("#finding_view_hexdump").addClass("active");
        $("#modal_file_contents").hide();
        $("#modal_file_hexdump").show();
    },
    getHostName: function () {
        if (this.model.get("CommitUrl").indexOf("github") !== -1) return "Github";
        return "GitLab";
    },
    truncatedCommitMessage: function () {
        var message = this.model.trimmedCommitMessage();
        if (message.length <= 150) {
            return _.escape(message);
        }
        return _.escape(message.substr(0, 150)) + "…";
    },
    isTestRelated: function () {
        return this.model.isTestRelated();
    },
    isBinary: function (data) {
        return /[\x00-\x08\x0E-\x1F]/.test(data);
    },
    highlightInterestingStrings: function (haystack) {
        this.interestingStringPatterns.forEach(function (pattern) {
            haystack = haystack.replace(pattern, "<mark>$1</mark>");
        });
        return haystack;
    },
    fetchFileContents: function () {
        if (this.model.get("Action") == "Delete") {
            var content = "<div class='alert alert-info' role='alert'>View commit on %s to see contents of deleted files.</div>";
            var host = this.getHostName();
            var fadeInFunc = function () {
                $("#modal_file_contents_container").html(content.replace("%s", host)).fadeIn("fast");
                $('.modal-content #view-file, #finding_view_raw, #finding_view_hexdump').addClass('disabled');
            };
            $("#modal_file_spinner_container").fadeOut("fast", fadeInFunc());
            return;
        }
        var context = this;
        this.model.fileContents(function (data) {
            var worker = new Worker("/javascripts/highlight_worker.js");
            worker.onmessage = function (event) {
                $("#modal_file_spinner_container").fadeOut("fast", _.bind(function () {
                    var content = this.highlightInterestingStrings(event.data);
                    $("#modal_file_contents").html(content);
                    new Hexdump(data, {
                        container: "modal_file_hexdump",
                        base: "hex",
                        width: 8,
                        byteGrouping: 1,
                        html: true,
                        ascii: true,
                        lineNumbers: true,
                        style: {
                            lineNumberLeft: '',
                            lineNumberRight: ':',
                            stringLeft: '|',
                            stringRight: '|',
                            hexLeft: '',
                            hexRight: '',
                            hexNull: '.',
                            nonPrintable: '.',
                            stringNull: '.',
                        }
                    });
                    $("#modal_file_contents_container").fadeIn("fast");
                    if (this.isBinary(data)) {
                        this.showHexDumpContents();
                    } else {
                        this.showRawContents();
                    }
                }, context));
            };
            worker.postMessage(data);
        }, function () {
            $("#modal_file_spinner_container").fadeOut("fast", function () {
                $("#modal_file_contents_container").html("<div class='alert alert-warning' role='alert'>File size too large to display inline. View file on GitHub.</div>").fadeIn("fast");
            });
        });
    }
});
