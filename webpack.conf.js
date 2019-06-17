const webpack = require('webpack');
const path = require('path');
const convert = require('koa-connect');
const history = require('connect-history-api-fallback');
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const WebpackNotifierPlugin = require('webpack-notifier');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

/**
 * Configuration valid both for development and production environments.
 */
const common = {
    entry: {
        index: './src/index.js'
    },
    output: {
        path: path.resolve(__dirname, 'build'),
        filename: 'js/[name].js',
        publicPath: '/'
    },
    optimization: {
        runtimeChunk: 'single',
        splitChunks: {
            chunks: 'all'
        }
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /(node_modules|elm)/,
                loader: 'babel-loader',

                options: {
                    presets: [
                        [
                            "@babel/preset-env",
                            {
                                targets: {
                                    browsers: ["last 2 versions", "safari >= 7"]
                                }
                            }]
                    ],
                    plugins: [
                        ["@babel/plugin-proposal-decorators", {legacy: true}],
                        ["@babel/plugin-proposal-class-properties", {loose: true}]
                    ]
                }
            },
            {
                test: /\.(png|jpg|gif|ttf|woff|woff2|eot|svg)$/,
                loader: 'file-loader',
                options: {
                    name: "[path][name].[ext]",
                    context: 'static',
                }
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: 'src/index.html',
            inject: 'body',
            filename: 'index.html'
        }),
        new CopyWebpackPlugin([
            {from: 'src/images/', to: 'images/'},
            {from: 'src/robots.txt'}
        ]),
        new webpack.DefinePlugin({
            'global.config': {
                app: {
                    firestore: {
                        apiKey: JSON.stringify('XXX'),
                        authDomain: JSON.stringify('XXX'),
                        projectId: JSON.stringify('XXX')
                    }
                }
            }
        }),
        new webpack.EnvironmentPlugin([
            "GOOGLE_API_KEY"
        ])
    ]
};

/**
 * Overrides/additions for development environment.
 */
const dev = {
    mode: 'development',
    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    {
                        loader: 'elm-hot-webpack-loader'
                    },
                    {
                        loader: 'elm-webpack-loader',
                        options: {
                            cwd: __dirname,
                            forceWatch: true,
                            debug: true
                        }
                    }
                ]
            },
            {
                test: /\.(scss|css)$/,
                use: [
                    'style-loader',
                    'css-loader',
                    'sass-loader'
                ]
            }
        ]
    },
    plugins: [
        new webpack.DefinePlugin({
            'global.config' : {
                logger : {}
            }
        }),
        new WebpackNotifierPlugin({
            title: 'elm-admin-dashboard',
            alwaysNotify: true
        })
    ],
    serve: {
        add: app => {
            app.use(convert(history()));
        }
    }
};

/**
 * Overrides/additions for production environment.
 *
 * UglifyJS is invoked twice according to recommendations from this page: https://guide.elm-lang.org/optimization/asset_size.html
 *
 */
const prod = {
    mode: 'production',
    output: {
        filename: 'js/[name].[contenthash].js',
    },
    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: 'elm-webpack-loader',
                options: {
                    optimize: true
                }
            },
            {
                test: /\.(scss|css)$/,
                use: [
                    MiniCssExtractPlugin.loader,
                    'css-loader',
                    'sass-loader'
                ]
            }
        ]
    },
    plugins: [
        new MiniCssExtractPlugin({
            filename: "css/index.css",
        }),
        new UglifyJSPlugin({
            uglifyOptions: {
                compress: {
                    pure_funcs: "F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",
                    pure_getters: true,
                    keep_fargs: false,
                    unsafe_comps: true,
                    unsafe: true
                }
            }
        }),
        new UglifyJSPlugin({
            uglifyOptions: {
                mangle: true
            }
        }),
        new OptimizeCssAssetsPlugin(),
        new BundleAnalyzerPlugin({
            analyzerMode: 'static',
            openAnalyzer: false
        })
    ]
};

module.exports = (function () {
    const buildingForProd = (function () {
        const m = process.argv.indexOf('--mode');
        return m >= 0 && m < process.argv.length - 1 && process.argv[m + 1] === 'production';
    })();

    const merge = require('webpack-merge');
    if (buildingForProd) {
        return merge(common, prod);
    }

    return merge(common, dev);
})();
